require 'test/unit'
require 'test/test_helper'

class VersionTest < Test::Unit::TestCase
  def test_version
    assert_equal '0.2.0', Sashimi::VERSION::STRING
  end
end
