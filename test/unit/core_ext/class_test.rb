require 'test/unit'
require 'test/test_helper'

class Repository
  def self.path
    @@path ||= 'path'
  end
  
  def self.another_path(another_path)
    another_path
  end
  
  class_method_proxy :path, :another_path
end

class ClassTest < Test::Unit::TestCase
  def test_should_respond_to_proxied_methods
    repository = Repository.new
    assert repository.send(:path)
    assert repository.send(:another_path, 'another_path')
  end
end
