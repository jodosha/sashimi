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
end
