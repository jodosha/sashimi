module Sashimi
  class GitRepository < AbstractRepository
    def install
      prepare_installation
      puts plugin.guess_name.titleize + "\n\n"
      system("git clone #{plugin.url}")
      add_to_cache(plugin.to_hash)
    end
    
    def update
      puts plugin.name.titleize + "\n\n"
      change_dir_to_plugin_path
      system('git pull')
    end
  end
end
