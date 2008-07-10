require 'test/unit'
require 'test/test_helper'

class ArrayTest < Test::Unit::TestCase
  uses_mocha 'ArrayTest' do
    def setup
      File.stubs(:SEPARATOR).returns '/'
    end

    def test_to_path  
      assert_equal 'path/to/app', %w(path to app).to_path
    end

    def test_to_absolute_path
      actual = File.dirname(__FILE__)
      expected = File.expand_path actual
      assert_equal expected, actual.split(File::SEPARATOR).to_path(true)
      assert_equal expected, actual.split(File::SEPARATOR).to_absolute_path
      assert_equal expected, actual.split(File::SEPARATOR).to_abs_path
    end
  end
end
