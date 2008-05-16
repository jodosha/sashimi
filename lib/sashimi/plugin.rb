module Sashimi
  class Plugin
    attr_reader :url, :name
    
    def initialize(name, url = '')
      @url = URI::parse(url).to_s
      @name = name
    end
    
    # Install the plugin
    def install
      repository.install
    end
    
    # Uninstall the plugin
    def uninstall
      repository.uninstall
    end
    
    # Update the plugin
    def update
      repository.update
    end
        
    def repository #:nodoc:
      @repository ||= instantiate_repository
    end
    
    # Try to guess the plugin name.
    def guess_name
      name = File.basename(@url)
      if name == 'trunk' || name.empty?
        name = File.basename(File.dirname(@url))
      end
      name.gsub!(/\.git$/, '') if name =~ /\.git$/
      name
    end
    
    class << self
      # List all installed plugins.
      def list
        AbstractRepository.list
      end
    end
        
  private
    # Instantiate the repository.
    # Look at <tt>AbstractRepository#instantiate_repository</tt> documentation.
    def instantiate_repository
      AbstractRepository.instantiate_repository(self)
    end      
  end
end
