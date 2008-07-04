require 'test/unit'
require 'test/test_helper'

class GitRepositoryTest < Test::Unit::TestCase
  def test_type
    assert_equal('git', GitRepository.new(nil).scm_type)
  end
  
  uses_mocha 'test_git_system_calls_for_install_and_update_process' do
    def test_should_raise_exception_for_unexistent_repository
      Kernel.expects(:system).with('git clone unexistent').raises(Errno::ENOENT)
      repository = GitRepository.new(create_plugin(nil, 'unexistent'))
      assert_raise(Errno::ENOENT) { repository.install }
    end
    
    def test_should_raise_exception_for_non_repository_url
      Kernel.expects(:system).with('git clone http://github.com/jodosha.git').raises(Errno::ENOENT)
      repository = GitRepository.new(create_plugin(nil, 'http://github.com/jodosha.git'))
      assert_raise(Errno::ENOENT) { repository.install }      
    end
    
    def test_should_create_git_repository
      repository.with_path plugins_path do
        FileUtils.mkdir_p('sashimi')
        Kernel.expects(:system).with('git clone git://github.com/jodosha/sashimi.git')
        GitRepository.new(plugin).install
        File.expects(:exists?).with('.git').returns(true)
        assert File.exists?('.git')
      end
    end    
  end
end
