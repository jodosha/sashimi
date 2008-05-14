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
    initialize_repository_for_test do
      assert File.exists?(repository.local_repository_path)
      assert_equal(repository.local_repository_path, Dir.pwd)
      assert File.exists?(repository.cache_file)
    end
  end
  
  def test_should_add_plugin_to_the_cache
    initialize_repository_for_test do
      expected = cache_content.merge(plugin)
      repository.add_to_cache(plugin)
      assert_equal expected, cache_content
    end
  end
  
  def test_should_remove_plugin_from_cache
    initialize_repository_for_test do
      AbstractRepository.new('http://svn.com/plugin/trunk', 'plugin').remove_from_cache
      assert_equal({}, cache_content)
    end
  end
  
private
  def cache_content
    FileUtils.cd(repository.local_repository_path)
    YAML::load_file(repository.cache_file).to_hash
  end
  
  def plugin
    {'click-to-globalize' => {'type' => 'git'}}
  end
end
