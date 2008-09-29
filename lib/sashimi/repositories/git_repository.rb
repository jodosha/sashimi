module Sashimi
  class GitNotFound < ClientNotFound; end #:nodoc:

  class GitRepository < AbstractRepository
    # Install the +plugin+.
    def install
      prepare_installation
      puts plugin.guess_name.titleize + "\n\n"
      with_path local_repository_path do
        result = Kernel.system("git clone #{plugin.url}")
        raise GitNotFound unless !!result
        add_to_cache(plugin.to_hash)
      end
    end
    
    # Update the +plugin+.
    def update
      puts plugin.name.titleize + "\n\n"
      with_path plugin_path do
        result = Kernel.system('git pull')
        raise GitNotFound unless !!result
      end
    end
  end
end
