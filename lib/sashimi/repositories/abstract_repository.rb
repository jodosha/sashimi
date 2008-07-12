module Sashimi
  class PluginNotFound < StandardError #:nodoc:
    def initialize(plugin_name, message = nil)
      @plugin_name, @message = plugin_name, message
    end

    def to_s
      @message || @plugin_name.to_s + " isn't in the local repository."
    end
  end
  
  class AbstractRepository
    TEMP_SUFFIX = '-tmp'
    @@plugins_path = ".rails/plugins".to_path
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
        unless plugin.name.nil?
          instantiate_repository_by_cache(plugin)
        else
          instantiate_repository_by_url(plugin)
        end.new(plugin)
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
        if under_version_control?
          update_versioned_rails_plugins(plugins_names)
        else
          update_unversioned_rails_plugins(plugins_names)
        end
      end

      # Update the plugins installed in a non versioned rails app.
      def update_unversioned_rails_plugins(plugins_names)
        plugins_names.each do |plugin_name|
          FileUtils.rm_rf [ absolute_rails_plugins_path, plugin_name ].to_path
          Plugin.new(plugin_name).add
        end
      end

      # Update the plugins installed in a versioned rails app.
      def update_versioned_rails_plugins(plugins_names)
        with_path absolute_rails_plugins_path do
          plugins_names.each do |plugin_name|
            raise PluginNotFound.new(plugin_name) unless File.exists?(plugin_name)
            repository = Plugin.new(plugin_name).repository
            repository.copy_plugin_and_remove_hidden_folders
            files_scheduled_for_remove = repository.files_scheduled_for_remove
            files_scheduled_for_add    = repository.files_scheduled_for_add
            FileUtils.cp_r(repository.temp_plugin_name+'/.', plugin_name)
            repository.remove_temp_folder
            with_path plugin_name do
              files_scheduled_for_remove.each {|file| scm_remove file}
              files_scheduled_for_add.each {|file| scm_add file}
            end
          end
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
        Kernel.system("#{scm} #{command} #{file}")
      end

      def local_repository_path #:nodoc:
        @local_repository_path ||= [ find_home, @@plugins_path ].to_path
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
        @@absolute_rails_plugins_path ||= [ path_to_rails_app,
          rails_plugins_path ].to_path(true)
      end
      
      # Rails app plugins dir
      def rails_plugins_path
        @@rails_plugins_path ||= "vendor/plugins".to_path
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
        (YAML::load_file('about.yml') rescue {}).to_hash
      end
    end

    # Returns a list of files that should be scheduled for SCM add.
    def files_scheduled_for_add
      Dir[temp_plugin_name+"/**/*"].collect {|fn| fn.gsub(temp_plugin_name, '.')} -
        Dir[plugin.name+"/**/*"].collect{|fn| fn.gsub(plugin.name, '.')}
    end
    
    # Returns a list of files that should be scheduled for SCM remove.
    def files_scheduled_for_remove
      Dir[plugin.name+"/**/*"].collect {|fn| fn.gsub(plugin.name, '.')} -
        Dir[temp_plugin_name+"/**/*"].collect {|fn| fn.gsub(temp_plugin_name, '.')}
    end
    
    # Remove the temp folder, used by update process.
    def remove_temp_folder
      FileUtils.rm_rf [ absolute_rails_plugins_path, temp_plugin_name ].to_path
    end
    
    # Returns the name used for temporary plugin folder.
    def temp_plugin_name
      plugin.name + TEMP_SUFFIX
    end

    class_method_proxy :local_repository_path, :cache_file,
      :cache_content, :path_to_rails_app, :rails_plugins_path,
      :with_path, :absolute_rails_plugins_path

  private
    # Returns the path to the plugin
    def plugin_path
      [ local_repository_path, plugin.name || plugin.guess_name ].to_path
    end

    # Prepare the plugin installation
    def prepare_installation
      FileUtils.mkdir_p local_repository_path
      FileUtils.touch [ local_repository_path, cache_file ].to_path
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
      File.atomic_write(cache_file) do |file|
        file.write(plugins.to_yaml)
      end
    end
    
    # Copy a plugin to a Rails app.
    def copy_plugin_to_rails_app
      FileUtils.mkdir_p absolute_rails_plugins_path
      FileUtils.cp_r [ local_repository_path, plugin.name ].to_path,
        [ absolute_rails_plugins_path, temp_plugin_name ].to_path
    end
    
    # Rename the *-tmp folder used by the installation process.
    #
    # Example:
    #   click-to-globalize-tmp # => click-to-globalize
    def rename_temp_folder
      FileUtils.mv [ rails_plugins_path, temp_plugin_name ].to_path,
        [ rails_plugins_path, plugin.name ].to_path
    end
    
    # Remove SCM hidden folders.
    def remove_hidden_folders
      require 'find'
      with_path [ absolute_rails_plugins_path, temp_plugin_name ].to_path do
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
      install_hook_file = [ rails_plugins_path, plugin.name, 'install.rb' ].to_path
      Kernel.load install_hook_file if File.exists? install_hook_file
    end
  end
end
