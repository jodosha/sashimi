$: << File.dirname(__FILE__) + "/../lib"
require 'sashimi'

class Test::Unit::TestCase
  include Sashimi
  
  def assert_not(condition, message = nil)
    assert !condition, message
  end
end

module Sashimi
  class Plugin
    public :git_url?
  end
  
  class AbstractRepository
    @@local_repository_sub_path = 'sashimi_test/.rails/plugins'
    public :local_repository_path, :change_dir, :prepare_installation
  end
end
