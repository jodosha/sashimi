module Sashimi
  class GitRepository < AbstractRepository
    def install
      prepare_installation
      system("git clone #{self.url}")
    end
  end
end