module Sashimi
  class SvnRepository < AbstractRepository
    def install
      prepare_installation
      system("svn co #{self.url} #{plugin_name}")
    end
  end
end
