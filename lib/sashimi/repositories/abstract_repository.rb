module Sashimi
  class AbstractRepository
    @@local_repository_sub_path = File.join('.rails', 'plugins')
    @@cache_file = '.plugins'
    attr_accessor :url, :plugin_name
    
    def initialize(url, plugin_name)
      @url, @plugin_name = url, plugin_name
    end
    
    # Remove the repository
    def uninstall
      change_dir(local_repository_path)
      raise plugin_name+" isn't in the local repository." unless File.exists?(plugin_name)
      FileUtils.rm_rf(plugin_name)
    end
    
    class << self
      def local_repository_path # :nodoc:
        @local_repository_path ||= File.join(find_home, @@local_repository_sub_path) 
      end

      def cache_file # :nodoc:
        @@cache_file
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
    end
    
  private
    # Changes the current directory to the given directory
    def change_dir(dir)
      FileUtils.cd(dir)
    end
    
    # Proxy for <tt>AbstractRepository#local_repository_path</tt>
    def local_repository_path
      self.class.local_repository_path
    end
    
    # Proxy for <tt>AbstractRepository#cache_file</tt>
    def cache_file
      self.class.cache_file
    end
    
    # Prepare the plugin installation
    def prepare_installation
      FileUtils.mkdir_p(local_repository_path)
      change_dir(local_repository_path)
      FileUtils.touch(cache_file)
    end
    
    # Add a plugin into the cache
    def add_to_cache(plugin)
      cache = YAML::load_file(cache_file) || {}
      write_to_cache cache.to_hash.merge!(plugin)
    end

    # Write all the plugins into the cache
    def write_to_cache(plugins)
      FileUtils.mv(cache_file, "#{cache_file}-backup")
      File.open(cache_file, 'w'){|f| f.write(plugins.to_yaml)}
      FileUtils.rm("#{cache_file}-backup")
    end
  end
end