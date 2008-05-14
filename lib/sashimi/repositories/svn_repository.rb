module Sashimi
  class SvnRepository < AbstractRepository
    def install
      prepare_installation
      system("svn co #{self.url} #{plugin_name}")
      add_to_cache({plugin_name => {'type' => 'svn'}})
    end
  end
end
