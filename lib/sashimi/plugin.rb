module Sashimi
  class Plugin
    attr_accessor :url, :repository
    attr_reader :name
    
    def initialize(url)
      self.url = URI::parse(url).to_s
      guess_name
      instantiate_repository
    end
    
  private
    def instantiate_repository
      self.repository = if git_url?
        GitRepository
      else
        SvnRepository
      end.new(self.url, self.name)
    end
    
    # Try to guess the plugin name.
    def guess_name
      @name = File.basename(self.url)
      if @name == 'trunk' || @name.empty?
        @name = File.basename(File.dirname(self.url))
      end
      @name.gsub!(/\.git$/, '') if @name =~ /\.git$/
    end
    
    # Try to guess if it's a Git repository.
    def git_url?
      self.url =~ /^git:\/\// || self.url =~ /\.git$/
    end
  end
end
