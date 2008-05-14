module Sashimi
  class GitRepository < AbstractRepository
    def install
      prepare_installation
      system("git clone #{self.url}")
      add_to_cache({plugin_name => {'type' => 'git'}})
    end
  end
end