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
      copy_plugin_to_rails_app
      remove_hidden_folders
      run_install_hook
    end
       
    class << self
      def instantiate_repository(plugin)
        unless plugin.name.nil?
          instantiate_repository_by_cache(plugin)
        else
          instantiate_repository_by_url(plugin)
        end.new(plugin)
      end

      # Return all installed plugin names
      def list
        cache_content.sort.collect do |plugin, contents|
          "#{plugin}\t\t#{contents['summary']}"
        end.join("\n")
      end

      def local_repository_path #:nodoc:
        @local_repository_path ||= File.join(find_home, @@local_repository_sub_path) 
      end

      def cache_file #:nodoc:
        @@cache_file
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
      
      # Rails app plugins dir
      def plugins_dir
        @@plugins_dir ||= File.join('vendor', 'plugins')
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
    
  private
    # Proxy for <tt>AbstractRepository#change_dir</tt>
    def change_dir(dir)
      self.class.change_dir(dir)
    end
    
    # Proxy for <tt>AbstractRepository#change_dir_to_local_repository</tt>
    def change_dir_to_local_repository
      self.class.change_dir_to_local_repository
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
      FileUtils.mkdir_p(plugins_dir)
      FileUtils.cp_r(File.join(local_repository_path, plugin.name), File.join(plugins_dir, plugin.name))
    end
    
    # Remove SCM hidden folders.
    # TODO: make working on Windows platform.
    def remove_hidden_folders
      system(%(find vendor/plugins/#{plugin.name} -name ".#{scm_type}" -type d -print | xargs rm -rf {}))
    end
    
    # Run the plugin install hook.
    def run_install_hook
      install_hook_file = File.join(plugins_dir, plugin.name, 'install.rb')
      load install_hook_file if File.exist? install_hook_file
    end
  end
end
