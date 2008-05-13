require 'test/unit'
require 'test/test_helper'

class PluginTest < Test::Unit::TestCase
  def test_initialize
    assert plugin
    assert plugin.name
    assert plugin.repository
  end
  
  def test_should_raise_invalid_uri_exception_on_nil_url
    assert_raise(URI::InvalidURIError) { plugin(nil) }
  end
  
  def test_should_guess_name_for_git_url
    assert_equal 'sashimi', plugin.name
  end
  
  def test_should_guess_name_for_svn_url
    assert_equal 'sashimi', plugin('http://dev.repository.com/svn/sashimi').name
    assert_equal 'sashimi', plugin('http://dev.repository.com/svn/sashimi/trunk').name
  end

  def test_should_instantiate_git_repository_for_git_url
    assert_kind_of GitRepository, plugin.repository
  end

  def test_should_instantiate_svn_repository_for_svn_url
    assert_kind_of SvnRepository, plugin('http://dev.repository.com/svn/sashimi/trunk').repository
  end

  def test_should_return_false_on_git_check_on_bad_url
    assert_not plugin('bad_url').git_url?
  end
        
  def test_should_return_true_on_git_check_for_git_repository
    assert plugin.git_url?
    assert plugin('http://github.com/jodosha/sashimi.git').git_url?
  end

private
  def plugin(url = 'git://github.com/jodosha/sashimi.git')
    Plugin.new(url)
  end
end
