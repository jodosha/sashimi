module Sashimi
  class GitRepository < AbstractRepository
    def install
      prepare_installation
      system("git clone #{plugin.url}")
      add_to_cache({plugin.guess_name => {'type' => 'git'}})
    end
  end
end