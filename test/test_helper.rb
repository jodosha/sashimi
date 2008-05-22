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
    create_plugin_directories
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
    { 'sashimi' => {'type' => 'git'}, 
      'plugin'  => {'type' => 'svn'},
      'plug-in' => {'type' => 'svn'} }
  end

  def create_plugin_directories
    { 'plugin' => true, 'plug-in' => false }.each do |plugin, about|
      create_plugin_directory(plugin, about)
    end
  end

  def create_plugin_directory(plugin, about = true)
    AbstractRepository.change_dir_to_local_repository
    FileUtils.mkdir(plugin) unless File.exists?(plugin)
    FileUtils.cd(plugin)
    File.open('about.yml', 'w+'){|f| f.write({'summary' => "Plugin summary"}.to_yaml)} if about
    AbstractRepository.change_dir_to_local_repository
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
      :change_dir_to_plugin_path, :plugins_dir, :copy_plugin_to_rails_app
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
