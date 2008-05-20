require 'test/unit'
require 'test/test_helper'

class AbstractRepositoryTest < Test::Unit::TestCase
  def test_initialize
    assert repository
    assert repository.plugin.name
    assert repository.plugin.url
  end
  
  # CLASS CONSTANTS
  def test_local_repository_path
    assert_match(/\.rails\/plugins$/, repository.local_repository_path)
  end
  
  def test_cache_file
    assert_equal(".plugins", repository.cache_file)
  end

  def test_plugins_dir
    assert_equal('vendor/plugins', repository.plugins_dir)
  end

  # INSTANTIATE
  def test_should_instantiate_repository_by_url
    assert_kind_of(SvnRepository, AbstractRepository.instantiate_repository(create_plugin(nil, 'http://svn.com')))
    assert_kind_of(GitRepository, AbstractRepository.instantiate_repository(plugin))
  end
  
  def test_should_instantiate_repository_by_cache
    initialize_repository_for_test do
      assert AbstractRepository.instantiate_repository(create_plugin('sashimi', ''))
    end
  end
  
  def test_should_recognize_git_url
    assert AbstractRepository.git_url?('git://github.com/jodosha/sashimi.git')
  end
  
  # COMMANDS
  def test_should_list_all_installed_plugins
    initialize_repository_for_test do
      assert_equal("plug-in\t\t\nplugin\t\t\nsashimi\t\t", AbstractRepository.list)
    end
  end
  
  def test_should_return_all_installed_plugins_names
    initialize_repository_for_test do
      assert_equal(['plug-in', 'plugin'], AbstractRepository.plugins_names)
    end
  end
  
  # DIRECTORIES
  def test_should_change_current_dir
    repository.change_dir(repository.class.find_home)
    assert_equal(repository.class.find_home, Dir.pwd)
  end
  
  def test_should_change_current_dir_with_local_repository_path
    initialize_repository_for_test do
      repository.change_dir_to_local_repository
      assert_equal(repository.local_repository_path, Dir.pwd)
    end
  end
  
  def test_should_change_current_dir_with_plugin_cache_path
    initialize_repository_for_test do
      FileUtils.mkdir_p(cached_plugin_path)
      repository.change_dir_to_plugin_path
      assert_equal(cached_plugin_path, Dir.pwd)
    end
  end
  
  def _ignore_test_should_copy_plugin_to_a_rails_app
    initialize_repository_for_test do
      repository.change_dir_to_local_repository
      create_repository('plugin', '').copy_plugin_to_rails_app
      assert File.exists?(File.join('vendor', 'plugins', 'plugin', 'about.yml'))
    end
  end
  
  # REPOSITORY
  def test_should_prepare_installation
    initialize_repository_for_test do
      assert File.exists?(repository.local_repository_path)
      assert_equal(repository.local_repository_path, Dir.pwd)
      assert File.exists?(repository.cache_file)
    end
  end

  # CACHE
  def test_should_read_cache_content
    initialize_repository_for_test do
      assert_equal(cache_content, repository.cache_content)
    end
  end
  
  def test_should_add_plugin_to_the_cache
    initialize_repository_for_test do
      expected = cache_content.merge(cached_plugin)
      repository.add_to_cache(cached_plugin)
      assert_equal expected, cache_content
    end
  end
  
  def test_should_remove_plugin_from_cache
    initialize_repository_for_test do
      AbstractRepository.new(create_plugin('sashimi', '')).remove_from_cache
      assert_equal({"plugin"=>{"type"=>"svn"}, "plug-in"=>{"type"=>"svn"}}, cache_content)
    end
  end
  
  # ABOUT
  def test_should_return_about_contents_from_about_yml
    initialize_repository_for_test do
      plugin = create_plugin('plugin', 'http://dev.repository.com/svn/plugin/trunk')
      assert_equal({'summary' => "Plugin summary"}, plugin.about)
    end
  end
  
  def test_should_return_empty_hash_for_unexstistent_about_yml
    initialize_repository_for_test do
      
      plugin = create_plugin('plug-in', 'http://dev.repository.com/svn/plug-in/trunk')
      assert_equal({}, plugin.about)
    end
  end
  
private
  def cache_content
    FileUtils.cd(repository.local_repository_path)
    YAML::load_file(repository.cache_file).to_hash
  end
    
  def cached_plugin_path
    File.join(repository.local_repository_path, 'sashimi')
  end
end
