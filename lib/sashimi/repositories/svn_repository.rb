module Sashimi
  class SvnRepository < AbstractRepository
    def install
      prepare_installation
      puts plugin.guess_name.titleize + "\n\n"
      Kernel.system("svn co #{plugin.url} #{plugin.guess_name}")
      add_to_cache(plugin.to_hash)
    end
    
    def update
      puts plugin.name.titleize + "\n\n"
      with_path plugin_path do
        Kernel.system("svn up")
      end
    end
  end
end
