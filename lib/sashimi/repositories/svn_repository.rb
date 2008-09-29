module Sashimi
  class SvnNotFound < ClientNotFound; end #:nodoc:

  class SvnRepository < AbstractRepository
    # Install the +plugin+.
    def install
      prepare_installation
      puts plugin.guess_name.titleize + "\n\n"
      with_path local_repository_path do
        result = Kernel.system("svn co #{plugin.url} #{plugin.guess_name}")
        raise SvnNotFound unless !!result
        add_to_cache(plugin.to_hash)
      end
    end
    
    # Update the +plugin+.
    def update
      puts plugin.name.titleize + "\n\n"
      with_path plugin_path do
        result = Kernel.system("svn up")
        raise SvnNotFound unless !!result
      end
    end
  end
end
