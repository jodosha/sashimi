require 'test/unit'
require 'test/test_helper'

class SvnRepositoryTest < Test::Unit::TestCase
  def test_type
    assert_equal('svn', SvnRepository.new(nil).scm_type)
  end
  
  uses_mocha 'test_svn_system_calls_for_install_and_update_process' do
    def test_should_raise_exception_for_unexistent_repository
      Kernel.expects(:system).with('svn co unexistent unexistent').raises(Errno::ENOENT)
      repository = SvnRepository.new(create_plugin(nil, 'unexistent'))
      assert_raise(Errno::ENOENT) { repository.install }
    end
    
    def test_should_raise_exception_for_non_repository_url
      Kernel.expects(:system).with('svn co http://sushistarweb.com sushistarweb.com').raises(Errno::ENOENT)
      repository = SvnRepository.new(create_plugin(nil, 'http://sushistarweb.com'))
      assert_raise(Errno::ENOENT) { repository.install }      
    end
    
    def test_should_create_svn_repository
      repository.with_path plugins_path do
        FileUtils.mkdir_p('sashimi')
        Kernel.expects(:system).with('svn co http://dev.repository.com/svn/sashimi/trunk sashimi').returns true
        SvnRepository.new(create_plugin(nil, 'http://dev.repository.com/svn/sashimi/trunk')).install
        File.expects(:exists?).with('.svn').returns(true)
        assert File.exists?('.svn')
      end
    end

    def test_should_raise_exception_if_svn_was_not_available
      assert_raise Sashimi::SvnNotFound do
        Kernel.expects(:system).with('svn co http://dev.repository.com/svn/sashimi/trunk sashimi').returns false
        SvnRepository.new(create_plugin(nil, 'http://dev.repository.com/svn/sashimi/trunk')).install
      end
    end
  end
end
