require 'test/unit'
require 'test/test_helper'

class GitRepositoryTest < Test::Unit::TestCase
  def test_type
    assert_equal('git', GitRepository.new(nil).scm_type)
  end
end