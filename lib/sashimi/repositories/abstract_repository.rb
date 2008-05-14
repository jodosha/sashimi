module Sashimi
  class AbstractRepository
    @@local_repository_sub_path = File.join('.rails', 'plugins')
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
    
    # Prepare the plugin installation
    def prepare_installation
      FileUtils.mkdir_p(local_repository_path)
      change_dir(local_repository_path)
    end
  end
end