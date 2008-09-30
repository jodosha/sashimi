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
  
  def test_temp_suffix
    assert_equal '-tmp', AbstractRepository::TEMP_SUFFIX
  end
  
  ### INSTANTIATE
  
  def test_instantiate_repository
    assert_kind_of GitRepository, repository.class.instantiate_repository(plugin)
    assert_kind_of GitRepository, repository.class.instantiate_repository(create_plugin('sashimi', plugin.url))
  end
  
  def test_should_instantiate_repository_by_url
    assert_equal SvnRepository, AbstractRepository.instantiate_repository_by_url(create_plugin(nil, 'http://svn.com'))
    assert_equal GitRepository, AbstractRepository.instantiate_repository_by_url(plugin)
  end
  
  def test_should_instantiate_repository_by_cache
    assert repository.class.instantiate_repository_by_cache(create_plugin('sashimi', plugin.url))
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
  def test_should_list_installed_plugins
    assert_equal cached_plugins, repository.class.list
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
      AbstractRepository.expects(:find_home).returns '/Users/luca'
      File.stubs(:SEPARATOR).returns '/'
      expected = [ repository.class.find_home, repository.class.plugins_path ].to_path
      assert_equal expected, repository.local_repository_path
    end
    
    def _ignore_test_find_home
      flunk
    end
    
    def test_with_path
      old_path = Dir.pwd
      repository.with_path 'test' do
        assert_equal [old_path, 'test'].to_path, Dir.pwd
      end
      assert_equal old_path, Dir.pwd
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
  
  ### FILES
    
  uses_mocha 'AbstractRepositoryTestFile' do
    def _ignore_test_copy_plugin_and_remove_hidden_folders
      flunk
    end

    def test_update_rails_plugins
      AbstractRepository.expects(:under_version_control?).returns true
      AbstractRepository.expects(:update_versioned_rails_plugins)
      AbstractRepository.update_rails_plugins plugin.name

      AbstractRepository.expects(:under_version_control?).returns false
      AbstractRepository.expects(:update_unversioned_rails_plugins)
      AbstractRepository.update_rails_plugins plugin.name
    end

    def _ignore_test_update_unversioned_rails_plugins
      FileUtils.stubs(:rm_rf) # because of teardown
      FileUtils.expects(:rm_rf).with 'sashimi'
      FileUtils.stubs(:cd)
      AbstractRepository.expects(:instantiate_repository_by_cache).returns GitRepository
      GitRepository.stubs(:cache_content).returns({ 'sashimi' => nil })
      Plugin.expects(:add)
      FileUtils.expects(:cp_r).with [ plugins_path, repository.plugin.name ].to_path,
        [ repository.class.rails_plugins_path, repository.temp_plugin_name ].to_path
      FileUtils.expects(:mv).with [ repository.rails_plugins_path, repository.temp_plugin_name ].to_path,
        [ repository.rails_plugins_path, repository.plugin.name ].to_path

      AbstractRepository.update_unversioned_rails_plugins 'sashimi'
    end

    def _ignore_test_update_versioned_rails_plugins
      flunk
    end

    def _ignore_test_files_scheduled_for_add
      flunk
    end

    def _ignore_test_files_scheduled_for_remove
      flunk
    end

    def test_remove_temp_folder
      with_path rails_app_path do
        FileUtils.expects(:rm_rf).with [ repository.absolute_rails_plugins_path,
          repository.temp_plugin_name].to_path
        repository.remove_temp_folder
        FileUtils.stubs(:rm_rf) # because of teardown
      end
    end

    def test_prepare_installation
      FileUtils.expects(:mkdir_p).with repository.local_repository_path
      FileUtils.expects(:touch).with [ repository.local_repository_path, cache_file ].to_path
      repository.prepare_installation
    end

    def test_copy_plugin_to_rails_app
      FileUtils.expects(:mkdir_p).with repository.absolute_rails_plugins_path
      FileUtils.expects(:cp_r).with [ repository.local_repository_path, repository.plugin.name ].to_path,
        [ repository.absolute_rails_plugins_path, repository.temp_plugin_name ].to_path
      repository.copy_plugin_to_rails_app
    end
  end

  def _ignore_test_remove_hidden_folders
    flunk
  end
  
  ### CACHE
  
  def test_cache_content
    assert_equal cached_plugins, repository.class.cache_content
  end
  
  uses_mocha 'TestAbstractRepositoryCache' do
    def test_should_add_a_new_plugin_to_cache
      with_clear_cache do
        with_path local_repository_path do
          create_plugin_directory('brand_new')
          plugin = create_plugin(nil, 'git://github.com/jodosha/brand_new.git')
          repository.add_to_cache(plugin)
          assert_equal cached_plugins.merge(plugin.to_hash), repository.class.cache_content
        end
      end
    end

    def test_should_merge_an_existent_plugin_into_cache
      File.expects(:atomic_write).with('.plugins', "./")
      with_clear_cache do
        with_path local_repository_path do
          repository.add_to_cache(plugin)
          assert_equal cached_plugins.merge(plugin.to_hash), repository.class.cache_content
        end
      end
    end

    def test_remove_from_cache
      File.expects(:atomic_write).with('.plugins', "./")
      with_clear_cache do
        with_path local_repository_path do
          repository.remove_from_cache
          assert_not repository.class.plugins_names.include?(plugin.name)
        end
      end
    end

    def test_write_to_cache
      File.expects(:atomic_write).with('.plugins', "./")
      repository.class.expects(:cache_content).returns plugin.to_hash # mock the atomic write result
      with_clear_cache do
        with_path plugins_path do
          repository.write_to_cache(plugin.to_hash)
          assert_equal plugin.to_hash, repository.class.cache_content
        end
      end
    end
  end
  
  ### OTHER
  
  def test_should_load_about_yml
    assert_not_empty repository.about.keys
  end

  def test_should_return_empty_hash_for_unexistent_about_yml
    assert_nothing_raised Exception do
      assert_empty create_repository('plug-in').about.keys
    end
  end

  def test_temp_plugin_name
    assert_equal repository.plugin.name + AbstractRepository::TEMP_SUFFIX,
      repository.temp_plugin_name
  end
  
  uses_mocha 'AbstractRepositoryTestOther' do
    def test_should_run_install_hook
      File.expects(:exists?).returns true
      Kernel.expects(:load)
      repository.run_install_hook
    end

    def test_should_not_raise_exception_running_install_hook_with_missing_file
      assert_nothing_raised Exception do
        Kernel.expects(:load).never
        create_repository('plug-in').run_install_hook
      end
    end
  end
end
