require 'test/unit'
require 'test/test_helper'

class Repository
  def self.path
    @@path ||= 'path'
  end
  
  def self.another_path(another_path)
    another_path
  end
  
  def self.path_with_block(path, &block)
    block.call(path) if block_given?
    path
  end
  
  class_method_proxy :path, :another_path, :path_with_block
  public :path_with_block
end

class ClassTest < Test::Unit::TestCase
  def test_should_respond_to_proxied_methods
    repository = Repository.new
    assert_equal 'path', repository.send(:path)
    assert_equal 'path', repository.send(:another_path, 'path')
    assert_equal 'path', repository.path_with_block('path') { |path| path }
  end
end
