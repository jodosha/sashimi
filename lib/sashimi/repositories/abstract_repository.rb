module Sashimi
  class PluginNotFound < StandardError #:nodoc:
    def initialize(plugin_name, message = nil)
      @plugin_name, @message = plugin_name, message
    end

    def to_s
      @message || @plugin_name + " isn't in the local repository."
    end
  end
  
  class AbstractRepository
    @@plugins_path = File.join('.rails', 'plugins')
    @@cache_file = '.plugins'
    cattr_accessor :cache_file
    
    attr_reader :plugin
    
    def initialize(plugin)
      @plugin = plugin
    end
    
    # Remove the repository
    def uninstall
      with_path local_repository_path do
        raise PluginNotFound.new(plugin.name) unless File.exists?(plugin.name)
        FileUtils.rm_rf(plugin.name)
        remove_from_cache
      end
    end
    
    # Add to a Rails app.
    def add
      raise PluginNotFound.new(plugin.name) unless cache_content.keys.include?(plugin.name)
      puts plugin.name.titleize + "\n"
      copy_plugin_and_remove_hidden_folders
      rename_temp_folder
      run_install_hook
    end

    # Copy a plugin to a Rails app and remove SCM hidden folders
    def copy_plugin_and_remove_hidden_folders
      copy_plugin_to_rails_app
      remove_hidden_folders
    end

    class << self
      def instantiate_repository(plugin)
        with_path local_repository_path do
          unless plugin.name.nil?
            instantiate_repository_by_cache(plugin)
          else
            instantiate_repository_by_url(plugin)
          end.new(plugin)
        end
      end

      # Return all installed plugin names and summary, formatted for stdout.
      def list
        cache_content.sort.collect do |plugin, contents|
          "#{plugin}\t\t#{contents['summary']}"
        end.join("\n")
      end

      # Return all installed plugins names.
      def plugins_names
        cache_content.keys.sort
      end

      # Update the plugins installed in a rails app.
      def update_rails_plugins(plugins_names)
        with_path path_to_rails_app do
          if under_version_control?
            update_versioned_rails_plugins(plugins_names)
          else
            update_unversioned_rails_plugins(plugins_names)
          end
        end
      end

      # Update the plugins installed in a non versioned rails app.
      def update_unversioned_rails_plugins(plugins_names)
        with_path rails_plugins_path do
          plugins_names.each do |plugin_name|
            FileUtils.rm_rf(plugin_name)
            Plugin.new(plugin_name).add
          end
        end
      end

      # Update the plugins installed in a versioned rails app.
      def update_versioned_rails_plugins(plugins_names)
        change_dir(plugins_dir)
        plugins_names.each do |plugin_name|
          raise PluginNotFound.new(plugin_name) unless File.exists?(plugin_name)
          repository = Plugin.new(plugin_name).repository
          repository.copy_plugin_and_remove_hidden_folders
          files_scheduled_for_remove = repository.files_scheduled_for_remove
          files_scheduled_for_add    = repository.files_scheduled_for_add
          FileUtils.cp_r(plugin_name+'-tmp/.', plugin_name)
          repository.remove_temp_folder
          change_dir(plugin_name)
          files_scheduled_for_remove.each {|file| scm_remove file}
          files_scheduled_for_add.each {|file| scm_add file}
        end
      end

      # Schedules an add for the given file on the current SCM system used by the Rails app.
      def scm_add(file)
        scm_command(:add, file)
      end

      def scm_remove(file)
        scm_command(:rm, file)
      end

      # Execute the given command for the current SCM system used by the Rails app.
      def scm_command(command, file)
        scm = guess_version_control_system
        system("#{scm} #{command} #{file}")
      end

      def local_repository_path #:nodoc:
        @local_repository_path ||= File.join(find_home, @@plugins_path) 
      end

      # Return the path to the Rails app where the user launched sashimi command.
      def path_to_rails_app
        $rails_app
      end

      # Read the cache file and return the content as an <tt>Hash</tt>.
      def cache_content
        with_path local_repository_path do
          @@cache_content ||= (YAML::load_file(cache_file) || {}).to_hash
        end
      end

      def instantiate_repository_by_url(plugin)
        git_url?(plugin.url) ? GitRepository : SvnRepository
      end

      def instantiate_repository_by_cache(plugin)
        cached_plugin = cache_content[plugin.name]
        raise PluginNotFound.new(plugin.name) if cached_plugin.nil?
        cached_plugin['type'] == 'git' ? GitRepository : SvnRepository
      end
            
      # Change the current directory with the fully qualified
      # path to Rails app and plugins_dir.
      def absolute_rails_plugins_path
        @@absolute_rails_plugins_path ||= File.join(File.expand_path(path_to_rails_app),
          rails_plugins_path)
      end
      
      # Rails app plugins dir
      def rails_plugins_path
        @@rails_plugins_path ||= File.join('vendor', 'plugins')
      end
      
      # Check if the current working directory is under version control
      def under_version_control?
        !Dir.glob(".{git,svn}").empty?
      end
      
      # Guess the version control system for the current working directory.
      def guess_version_control_system
        File.exists?('.git') ? :git : :svn
      end
      
      # Find the user home directory
      def find_home
        ['HOME', 'USERPROFILE'].each do |homekey|
          return ENV[homekey] if ENV[homekey]
        end
        if ENV['HOMEDRIVE'] && ENV['HOMEPATH']
          return "#{ENV['HOMEDRIVE']}:#{ENV['HOMEPATH']}"
        end
        begin
          File.expand_path("~")
        rescue StandardError => ex
          if File::ALT_SEPARATOR
            "C:/"
          else
            "/"
          end
        end
      end
      
      # Try to guess if it's a Git url.
      def git_url?(url)
        url =~ /^git:\/\// || url =~ /\.git$/
      end
      
      def with_path(path, &block)
        begin
          old_path = Dir.pwd
          FileUtils.cd(path)
          yield
        ensure
          FileUtils.cd(old_path)
        end
      end
    end

    # Return the SCM type
    #
    #   Subversion   # => svn
    #   Git          # => git
    def scm_type
      self.class.name.demodulize.gsub(/Repository$/, '').downcase
    end
    
    # Read the content of the <tt>about.yml</tt>.
    # New feature of Rails 2.1.x http:://dev.rubyonrails.org/changeset/9098
    def about
      with_path plugin_path do
        return {} unless File.exists?('about.yml')
        (YAML::load_file('about.yml') || {}).to_hash
      end
    end

    # Returns a list of files that should be scheduled for SCM add.
    def files_scheduled_for_add
      with_path absolute_rails_plugins_path do
        Dir[plugin.name+"-tmp/**/*"].collect {|fn| fn.gsub(plugin.name+'-tmp', '.')} -
          Dir[plugin.name+"/**/*"].collect{|fn| fn.gsub(plugin.name, '.')}
      end
    end
    
    # Returns a list of files that should be scheduled for SCM remove.
    def files_scheduled_for_remove
      with_path absolute_rails_plugins_path do
        Dir[plugin.name+"/**/*"].collect {|fn| fn.gsub(plugin.name, '.')} -
          Dir[plugin.name+"-tmp/**/*"].collect {|fn| fn.gsub(plugin.name+"-tmp", '.')}
      end
    end
    
    # Remove the temp folder, used by update process.
    def remove_temp_folder
      with_path absolute_rails_plugins_path do
        FileUtils.rm_rf(plugin.name+'-tmp')
      end
    end
    
    class_method_proxy :local_repository_path, :cache_file,
      :cache_content, :path_to_rails_app, :rails_plugins_path,
      :with_path, :absolute_rails_plugins_path

  private
    # Returns the path to the plugin
    def plugin_path
      File.join(local_repository_path, plugin.name || plugin.guess_name)
    end

    # Prepare the plugin installation
    def prepare_installation
      FileUtils.mkdir_p(local_repository_path)
      with_path local_repository_path do
        FileUtils.touch(cache_file)
      end
    end
    
    # Add a plugin into the cache
    def add_to_cache(plugin)
      write_to_cache cache_content.to_hash.merge!(plugin)
    end

    # Remove a plugin from the cache
    def remove_from_cache
      cache_content.delete(plugin.name)
      write_to_cache cache_content
    end

    # Write all the plugins into the cache
    def write_to_cache(plugins)
      with_path local_repository_path do
        FileUtils.mv(cache_file, "#{cache_file}-backup")
        File.open(cache_file, 'w'){|f| f.write(plugins.to_yaml)}
        FileUtils.rm("#{cache_file}-backup")
      end
    end
    
    # Copy a plugin to a Rails app.
    def copy_plugin_to_rails_app
      FileUtils.mkdir_p(plugins_path)
      FileUtils.cp_r(File.join(local_repository_path, plugin.name),
        File.join(rails_plugins_path, plugin.name+'-tmp'))
    end
    
    # Rename the *-tmp folder used by the installation process.
    #
    # Example:
    #   click-to-globalize-tmp # => click-to-globalize
    def rename_temp_folder
      FileUtils.mv(File.join(rails_plugins_path, plugin.name+'-tmp'),
        File.join(rails_plugins_path, plugin.name))
    end
    
    # Remove SCM hidden folders.
    def remove_hidden_folders
      require 'find'
      with_path File.join(absolute_rails_plugins_path, plugin.name + '-tmp') do
        Find.find('./') do |path|
          if File.basename(path) == '.'+scm_type
            FileUtils.remove_dir(path, true)
            Find.prune
          end
        end
      end
    end
    
    # Run the plugin install hook.
    def run_install_hook
      install_hook_file = File.join(rails_plugins_path, plugin.name, 'install.rb')
      load install_hook_file if File.exist? install_hook_file
    end
  end
end
