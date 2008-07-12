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

    # Add to a Rails app
    def add
      repository.add
    end

    def repository #:nodoc:
      @repository ||= instantiate_repository
    end

    # Returns the informations about the plugin.
    def about
      @about ||= repository.about
    end
    
    # Return the plugin summary.
    def summary
      about['summary']
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
    
    # Serialize the plugin to +Hash+ format.
    def to_hash
      { self.guess_name => 
        { 'type' => repository.scm_type,
          'summary' => self.summary } }
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
