module Sashimi
  class SvnRepository < AbstractRepository
    def install
      prepare_installation
      system("svn co #{plugin.url} #{plugin.guess_name}")
      add_to_cache({plugin.guess_name => {'type' => 'svn'}})
    end
    
    def update
      change_dir_to_plugin_path
      system("svn up")
    end
  end
end
