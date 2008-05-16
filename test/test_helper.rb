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

  def repository
    create_repository
  end

  def create_repository(plugin_name = 'sashimi', url = 'git://github.com/jodosha/sashimi.git')
    @repository ||= AbstractRepository.new(Plugin.new(plugin_name, url))
  end

  def plugin
    create_plugin(nil, 'git://github.com/jodosha/sashimi.git')
  end
  
  def create_plugin(name, url = nil)
    Plugin.new(name, url)
  end

  def cached_plugin
    {'sashimi' => {'type' => 'git'}}
  end

  def create_cache_file
    File.open(repository.cache_file, 'w+'){|f| f.write(cached_plugin.to_yaml)}
  end

  def remove_local_repository_path
    FileUtils.rm_rf(File.join(repository.class.find_home, 'sashimi_test'))
  end
end

module Sashimi
  class AbstractRepository
    @@local_repository_sub_path = 'sashimi_test/.rails/plugins'
    public :local_repository_path, :change_dir, :prepare_installation,
      :cache_file, :add_to_cache, :remove_from_cache,
      :cache_content, :change_dir_to_local_repository,
      :change_dir_to_plugin_path
  end
end
