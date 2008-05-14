$: << File.dirname(__FILE__) + "/../lib"
require 'sashimi'

class Test::Unit::TestCase
  include Sashimi
  
  def assert_not(condition, message = nil)
    assert !condition, message
  end
  
private
  def initialize_repository_for_test(&block)
    repository.prepare_installation
    create_cache_file
    yield
    remove_local_repository_path # make sure of clean up tmp dirs
  end

  def repository(url = 'git://github.com/jodosha/sashimi.git', plugin_name = 'sashimi')
    @repository ||= AbstractRepository.new(url, plugin_name)
  end

  def create_cache_file
    File.open(repository.cache_file, 'w+'){|f| f.write({'plugin' => {'type' => 'svn'}}.to_yaml)}
  end

  def remove_local_repository_path
    FileUtils.rm_rf(File.join(repository.class.find_home, 'sashimi_test'))
  end
end

module Sashimi
  class Plugin
    public :git_url?
  end
  
  class AbstractRepository
    @@local_repository_sub_path = 'sashimi_test/.rails/plugins'
    public :local_repository_path, :change_dir, :prepare_installation, :cache_file, :add_to_cache, :remove_from_cache
  end
end
