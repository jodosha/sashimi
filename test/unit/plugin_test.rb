require 'test/unit'
require 'test/test_helper'

class PluginTest < Test::Unit::TestCase
  def test_initialize
    assert plugin
    assert plugin.repository
    assert_nil plugin.name
  end
  
  def test_should_raise_invalid_uri_exception_on_nil_url
    assert_raise(URI::InvalidURIError) { create_plugin(nil, nil) }
  end
  
  def test_should_guess_name_for_git_url
    assert_equal 'sashimi', plugin.guess_name
  end
  
  def test_should_guess_name_for_svn_url
    assert_equal 'sashimi', create_plugin(nil, 'http://dev.repository.com/svn/sashimi').guess_name
    assert_equal 'sashimi', create_plugin(nil, 'http://dev.repository.com/svn/sashimi/trunk').guess_name
  end

  def test_should_instantiate_git_repository_for_git_url
    assert_kind_of GitRepository, plugin.repository
  end

  def test_should_instantiate_svn_repository_for_not_git_url
    assert_kind_of SvnRepository, create_plugin(nil, 'http://dev.repository.com/svn/sashimi/trunk').repository
  end
end
