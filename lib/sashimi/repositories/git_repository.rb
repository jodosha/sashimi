module Sashimi
  class GitRepository < AbstractRepository
    def install
      prepare_installation
      system("git clone #{plugin.url}")
      add_to_cache(plugin.to_hash)
    end
    
    def update
      change_dir_to_plugin_path
      system('git pull')
    end
  end
end
