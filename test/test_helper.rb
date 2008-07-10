$: << File.dirname(__FILE__) + "/../lib"
require 'sashimi'

class Test::Unit::TestCase
  include Sashimi
  
  def assert_not(condition, message = nil)
    assert !condition, message
  end
  
  # Asserts the given path exists
  # It accepts path/to/be/asserted and automatically make it cross platform.
  def assert_path_exists(path)
    assert File.exists?(path.to_path)
  end
  
private
  def create_test_repository
    prepare_installation
    with_path plugins_path do
      create_cache_file
      create_plugin_directories
      create_rails_app
    end
  end

  def destroy_test_repository
    FileUtils.rm_rf(local_repository_path)
  end

  alias_method :setup, :create_test_repository
  alias_method :teardown, :destroy_test_repository

  def local_repository_path
    @local_repository_path ||= File.join(repository.class.find_home, 'sashimi_test')
  end

  def plugins_path
    @plugins_path ||= File.join(local_repository_path, '.rails', 'plugins')
  end

  def rails_app_path
    @rails_app_path ||= begin 
      path = File.join(local_repository_path, '.rails', 'rails_app')
      $rails_app = path
      path
    end
  end

  def repository
    @repository ||= create_repository
  end

  def plugin
    @plugin ||= create_plugin(nil, 'git://github.com/jodosha/sashimi.git')
  end

  def create_repository(plugin_name = 'sashimi', url = 'git://github.com/jodosha/sashimi.git')
    AbstractRepository.new(Plugin.new(plugin_name, url))
  end
  
  def create_plugin(name, url = nil)
    Plugin.new(name, url)
  end

  def cached_plugin
    { 'sashimi' => {'type' => 'git'}, 
      'plugin'  => {'type' => 'svn'},
      'plug-in' => {'type' => 'svn'} }
  end

  def cache_file
    '.plugins'
  end

  def create_plugin_directories
    { 'sashimi' => true, 'plugin' => true, 'plug-in' => false }.each do |plugin, about|
      create_plugin_directory(plugin, about)
    end
  end

  def create_plugin_directory(plugin, about = true)
    FileUtils.mkdir(plugin) unless File.exists?(plugin)
    File.open(File.join(plugin, 'about.yml'), 'w+') do |f|
      f.write({'summary' => "Plugin summary"}.to_yaml)
    end if about
  end

  def create_rails_app
    FileUtils.mkdir_p(File.join(rails_app_path, 'vendor', 'plugins'))
  end

  def prepare_installation
    FileUtils.mkdir_p(plugins_path)
  end

  def create_cache_file
    File.open(cache_file, 'w+'){|f| f.write(cached_plugin.to_yaml)}
  end
  
  def with_local_repository_path(&block)
    with_path(local_repository_path, &block)
  end
  
  # FIXME why often Dir.pwd returns nil ?
  def with_path(path, &block)
    begin
      old_path = Dir.pwd rescue plugins_path
      FileUtils.cd(path)
      yield
    ensure
      FileUtils.cd(old_path)
    end
  end
end

module Sashimi
  class AbstractRepository
    @@plugins_path = 'sashimi_test/.rails/plugins'
    cattr_accessor :plugins_path
    public :add_to_cache, :cache_content, :cache_file,
      :copy_plugin_to_rails_app, :local_repository_path, :path_to_rails_app,
      :prepare_installation, :remove_from_cache, :rails_plugins_path,
      :remove_hidden_folders, :rename_temp_folder, :run_install_hook,
      :write_to_cache, :with_path, :plugin_path
  end
end

# Thanks to Rails Core Team
def uses_mocha(description)
  require 'rubygems'
  require 'mocha'
  yield
rescue LoadError
  $stderr.puts "Skipping #{description} tests. `gem install mocha` and try again."
end

def puts(message) #shut-up!
end
