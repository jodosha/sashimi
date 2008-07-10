require 'test/unit'
require 'test/test_helper'

class AbstractRepositoryTest < Test::Unit::TestCase
  include Sashimi
  
  def test_initialize
    assert repository.plugin
  end
  
  def test_plugins_path
    assert_equal 'sashimi_test/.rails/plugins', repository.class.plugins_path
  end
  
  def test_cache_file
    assert_equal cache_file, repository.class.cache_file
  end
  
  def test_plugins_names
    assert_equal cached_plugins.keys.sort, repository.class.plugins_names
  end
  
  ### COMMANDS
  
  # ADD
  def test_should_add_plugin_to_rails_app
    with_path rails_app_path do
      repository.add
      assert_path_exists "vendor/plugins/#{repository.plugin.name}"
    end
  end
  
  def test_should_raise_exception_on_adding_missing_plugin
    with_path rails_app_path do
      assert_raise PluginNotFound do
        create_repository('unexistent').add
      end
    end
  end
  
  # UNINSTALL
  def test_should_uninstall_plugin_from_repository
    repository.uninstall
    with_path plugins_path do
      assert_path_not_exists repository.plugin.name
    end
    assert_not repository.class.plugins_names.include?(repository.plugin.name)
  end
  
  def test_should_raise_exception_on_uninstalling_missing_plugin
    assert_raise PluginNotFound do
      create_repository('unexistent').uninstall
    end
  end
  
  # LIST
  # TODO cleanup
  def test_should_list_installed_plugins
    assert_equal "plug-in\t\t\nplugin\t\t\nsashimi\t\t", repository.class.list
  end
    
  ### SCM
  
  uses_mocha 'AbstractRepositoryTestSCM' do
    def test_guess_version_control_system
      File.expects(:exists?).with('.git').returns true
      assert_equal :git, repository.class.guess_version_control_system
      
      File.expects(:exists?).with('.git').returns false
      assert_equal :svn, repository.class.guess_version_control_system      
    end
    
    def test_scm_command
      File.stubs(:exists?).with('.git').returns true
      Kernel.expects(:system).with('git add file.rb')
      repository.class.scm_command('add', 'file.rb')
    end
    
    def test_scm_add
      File.stubs(:exists?).with('.git').returns true
      Kernel.expects(:system).with('git add file.rb')
      repository.class.scm_add('file.rb')
    end
    
    def test_scm_remove
      File.stubs(:exists?).with('.git').returns true
      Kernel.expects(:system).with('git rm file.rb')
      repository.class.scm_remove('file.rb')      
    end
    
    def test_under_version_control
      Dir.expects(:glob).with(".{git,svn}").returns %w(.git)
      assert repository.class.under_version_control?
    end    
  end
  
  def test_git_url
    assert repository.class.git_url?(plugin.url)
    assert repository.class.git_url?(plugin.url.gsub('git:', 'http:'))
    assert_not repository.class.git_url?('http://repository.com/plugin/trunk')
  end
  
  ### PATH
  
  uses_mocha 'AbstractRepositoryTestPath' do
    def test_local_repository_path
      AbstractRepository.stubs(:find_home).returns '/Users/luca'
      File.stubs(:SEPARATOR).returns '/'
      expected = [ repository.class.find_home, repository.class.plugins_path ].to_path
      assert_equal expected, repository.local_repository_path
    end
  end
  
  def test_path_to_rails_app
    with_path rails_app_path do
      assert_equal Dir.pwd, repository.class.path_to_rails_app
    end
  end
  
  def test_absolute_rails_plugins_path
    with_path rails_app_path do
      expected = "#{Dir.pwd}/vendor/plugins".to_path
      assert_equal expected, repository.class.absolute_rails_plugins_path
    end
  end
  
  def test_rails_plugins_path
    assert_equal 'vendor/plugins'.to_path, repository.class.rails_plugins_path
  end
  
  def test_plugin_path
    expected = [ plugins_path, repository.plugin.name ].to_path
    assert_equal expected, repository.plugin_path
  end
end
