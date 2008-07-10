require 'test/unit'
require 'test/test_helper'

class StringTest < Test::Unit::TestCase
  uses_mocha 'StringTest' do
    def setup
      File.stubs(:SEPARATOR).returns '/'      
    end
    
    def test_to_path
      assert_equal 'path/to/app', 'path/to/app'.to_path
    end
    
    def test_to_absolute_path
      actual = File.dirname(__FILE__)
      expected = File.expand_path actual
      assert_equal expected, actual.to_path(true)
    end
  end
end
