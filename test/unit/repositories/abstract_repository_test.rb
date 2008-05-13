require 'test/unit'
require 'test/test_helper'

class AbstractRepositoryTest < Test::Unit::TestCase
  def test_initialize
    assert repository
    assert repository.url
    assert repository.plugin_name
  end
  
  def test_local_repository_path
    assert_match(/\.rails\/plugins$/, repository.local_repository_path)
  end
  
  def test_should_change_current_dir
    repository.change_dir(repository.class.find_home)
    assert_equal(repository.class.find_home, Dir.pwd)
  end
  
  def test_should_prepare_installation
    repository.prepare_installation
    assert File.exists?(repository.local_repository_path)
    assert_equal(repository.local_repository_path, Dir.pwd)
    remove_local_repository_path # make sure to cleanup tmp directories
  end
  
private
  def repository(url = 'git://github.com/jodosha/sashimi.git', plugin_name = 'sashimi')
    @repository ||= AbstractRepository.new(url, plugin_name)
  end
  
  def remove_local_repository_path
    FileUtils.rm_rf(File.join(repository.class.find_home, 'sashimi_test'))
  end
end
