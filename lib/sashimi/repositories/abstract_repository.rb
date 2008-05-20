module Sashimi
  class PluginNotFound < StandardError #:nodoc:
    def initialize(plugin_name, message = nil)
      @plugin_name = plugin_name
      @message     = message
    end

    def to_s
      @message || @plugin_name + " isn't in the local repository."
    end
  end
  
  class AbstractRepository
    @@local_repository_sub_path = File.join('.rails', 'plugins')
    @@cache_file = '.plugins'
    attr_accessor :plugin
    
    def initialize(plugin)
      self.plugin = plugin
    end
    
    # Remove the repository
    def uninstall
      change_dir_to_local_repository
      raise PluginNotFound.new(plugin.name) unless File.exists?(plugin.name)
      FileUtils.rm_rf(plugin.name)
      remove_from_cache
    end
    
    # Add to a Rails app.
    def add
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
        change_dir(path_to_rails_app)
        if under_version_control?
          update_versioned_rails_plugins(plugins_names)
        else
          update_unversioned_rails_plugins(plugins_names)
        end
      end

      # Update the plugins installed in a non versioned rails app.
      def update_unversioned_rails_plugins(plugins_names)
        change_dir(plugins_dir)
        plugins_names.each do |plugin_name|
          FileUtils.rm_rf(plugin_name)
          Plugin.new(plugin_name).add
        end
      end

      # Update the plugins installed in a versioned rails app.
      def update_versioned_rails_plugins(plugins_names)
        change_dir(plugins_dir)
        plugins_names.each do |plugin_name|
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
        @local_repository_path ||= File.join(find_home, @@local_repository_sub_path) 
      end

      def cache_file #:nodoc:
        @@cache_file
      end

      # Return the path to the Rails app where the user launched sashimi command.
      def path_to_rails_app
        $rails_app
      end

      # Read the cache file and return the content as an <tt>Hash</tt>.
      def cache_content
        change_dir_to_local_repository
        @@cache_content ||= (YAML::load_file(cache_file) || {}).to_hash
      end

      def instantiate_repository_by_url(plugin)
        git_url?(plugin.url) ? GitRepository : SvnRepository
      end

      def instantiate_repository_by_cache(plugin)
        cached_plugin = cache_content[plugin.name]
        raise PluginNotFound.new(plugin.name) if cached_plugin.nil?
        cached_plugin['type'] == 'git' ? GitRepository : SvnRepository
      end

      # Changes the current directory with the given one
      def change_dir(dir)
        FileUtils.cd(dir)
      end
      
      # Change the current directory with local_repository_path
      def change_dir_to_local_repository
        change_dir(local_repository_path)
      end
      
      # Change the current directory with the fully qualified
      # path to Rails app and plugins_dir.
      def change_dir_to_absolute_plugins_dir
        change_dir(File.join(File.expand_path(path_to_rails_app), plugins_dir))
      end
      
      # Rails app plugins dir
      def plugins_dir
        @@plugins_dir ||= File.join('vendor', 'plugins')
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
      change_dir_to_plugin_path
      return {} unless File.exists?('about.yml')
      (YAML::load_file('about.yml') || {}).to_hash
    end

    # Returns a list of files that should be scheduled for SCM add.
    def files_scheduled_for_add
      change_dir_to_absolute_plugins_dir
      Dir[plugin.name+"-tmp/**/*"].collect {|fn| fn.gsub(plugin.name+'-tmp', '.')} -
        Dir[plugin.name+"/**/*"].collect{|fn| fn.gsub(plugin.name, '.')}
    end
    
    # Returns a list of files that should be scheduled for SCM remove.
    def files_scheduled_for_remove
      change_dir_to_absolute_plugins_dir
      Dir[plugin.name+"/**/*"].collect {|fn| fn.gsub(plugin.name, '.')} -
        Dir[plugin.name+"-tmp/**/*"].collect {|fn| fn.gsub(plugin.name+"-tmp", '.')}
    end
    
    # Remove the temp folder, used by update process.
    def remove_temp_folder
      change_dir_to_absolute_plugins_dir
      FileUtils.rm_rf(plugin.name+'-tmp')
    end
    
  private
    # Proxy for <tt>AbstractRepository#change_dir</tt>
    def change_dir(dir)
      self.class.change_dir(dir)
    end
    
    # Proxy for <tt>AbstractRepository#change_dir_to_local_repository</tt>
    def change_dir_to_local_repository
      self.class.change_dir_to_local_repository
    end
    
    # Proxy for <tt>AbstractRepository#change_dir_to_absolute_plugins_dir</tt>
    def change_dir_to_absolute_plugins_dir
      self.class.change_dir_to_absolute_plugins_dir
    end
    
    # Change the current directory with the plugin one
    def change_dir_to_plugin_path
      change_dir(File.join(local_repository_path, plugin.name || plugin.guess_name))
    end

    # Proxy for <tt>AbstractRepository#local_repository_path</tt>
    def local_repository_path
      self.class.local_repository_path
    end
    
    # Proxy for <tt>AbstractRepository#cache_file</tt>
    def cache_file
      self.class.cache_file
    end
    
    # Proxy for <tt>AbstractRepository#cache_content</tt>
    def cache_content
      self.class.cache_content
    end
    
    # Proxy for <tt>AbstractRepository#plugins_dir</tt>
    def plugins_dir
      self.class.plugins_dir
    end
    
    # Proxy for <tt>AbstractRepository#path_to_rails_app</tt>
    def path_to_rails_app
      self.class.path_to_rails_app
    end
    
    # Prepare the plugin installation
    def prepare_installation
      FileUtils.mkdir_p(local_repository_path)
      change_dir_to_local_repository
      FileUtils.touch(cache_file)
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
      change_dir_to_local_repository
      FileUtils.mv(cache_file, "#{cache_file}-backup")
      File.open(cache_file, 'w'){|f| f.write(plugins.to_yaml)}
      FileUtils.rm("#{cache_file}-backup")
    end
    
    # Copy a plugin to a Rails app.
    def copy_plugin_to_rails_app
      change_dir(path_to_rails_app)
      FileUtils.mkdir_p(plugins_dir)
      FileUtils.cp_r(File.join(local_repository_path, plugin.name), File.join(plugins_dir, plugin.name+'-tmp'))
    end
    
    # Rename the *-tmp folder used by the installation process.
    #
    # Example:
    #   click-to-globalize-tmp # => click-to-globalize
    def rename_temp_folder
      change_dir(path_to_rails_app)
      FileUtils.mv(File.join(plugins_dir, plugin.name+'-tmp'), File.join(plugins_dir, plugin.name))
    end
    
    # Remove SCM hidden folders.
    def remove_hidden_folders
      require 'find'
      change_dir(File.join(path_to_rails_app, plugins_dir, plugin.name+'-tmp'))
      Find.find('./') do |path|
        if File.basename(path) == '.'+scm_type
          FileUtils.remove_dir(path, true)
          Find.prune
        end
      end
    end
    
    # Run the plugin install hook.
    def run_install_hook
      install_hook_file = File.join(plugins_dir, plugin.name, 'install.rb')
      load install_hook_file if File.exist? install_hook_file
    end
  end
end
