require 'test/unit'
require 'test/test_helper'

class SvnRepositoryTest < Test::Unit::TestCase
  def test_type
    assert_equal('svn', SvnRepository.new(nil).scm_type)
  end
end