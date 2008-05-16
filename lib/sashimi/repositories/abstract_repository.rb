module Sashimi
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
      raise plugin.name+" isn't in the local repository." unless File.exists?(plugin.name)
      FileUtils.rm_rf(plugin.name)
      remove_from_cache
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
        cache_content.keys.sort
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
        raise plugin.name + " isn't in the local repository." if cached_plugin.nil?
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
      change_dir(File.join(local_repository_path, plugin.name))
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
      FileUtils.mv(cache_file, "#{cache_file}-backup")
      File.open(cache_file, 'w'){|f| f.write(plugins.to_yaml)}
      FileUtils.rm("#{cache_file}-backup")
    end
  end
end