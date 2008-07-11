module Sashimi
  class GitRepository < AbstractRepository
    def install
      prepare_installation
      puts plugin.guess_name.titleize + "\n\n"
      with_path local_repository_path do
        Kernel.system("git clone #{plugin.url}")
        add_to_cache(plugin.to_hash)
      end
    end
    
    def update
      puts plugin.name.titleize + "\n\n"
      with_path plugin_path do
        Kernel.system('git pull')
      end
    end
  end
end
