module Sashimi
  class SvnRepository < AbstractRepository
    # Install the +plugin+.
    def install
      prepare_installation
      puts plugin.guess_name.titleize + "\n\n"
      with_path local_repository_path do
        Kernel.system("svn co #{plugin.url} #{plugin.guess_name}")
        add_to_cache(plugin.to_hash)
      end
    end
    
    # Update the +plugin+.
    def update
      puts plugin.name.titleize + "\n\n"
      with_path plugin_path do
        Kernel.system("svn up")
      end
    end
  end
end
