Gem::Specification.new do |s|
  s.name               = "sashimi"
  s.version            = "0.1.5"
  s.date               = "2008-05-20"
  s.summary            = "Rails plugins manager"
  s.author             = "Luca Guidi"
  s.email              = "guidi.luca@gmail.com"
  s.homepage           = "http://lucaguidi.com/pages/sashimi"
  s.description        = "Sashimi is a local repository for Rails plugins."
  s.has_rdoc           = true
  s.rubyforge_project  = %q{sashimi}
  s.executables        = [ 'sashimi' ]
  s.files              = ["CHANGELOG", "MIT-LICENSE", "Rakefile", "README", "sashimi.gemspec", "setup.rb", "bin/sashimi", "lib/sashimi/commands.rb", "lib/sashimi/plugin.rb", "lib/sashimi/repositories/abstract_repository.rb", "lib/sashimi/repositories/git_repository.rb", "lib/sashimi/repositories/svn_repository.rb", "lib/sashimi/repositories.rb", "lib/sashimi.rb", "test/test_helper.rb", "test/unit/plugin_test.rb", "test/unit/repositories/abstract_repository_test.rb", "test/unit/repositories/git_repository_test.rb", "test/unit/repositories/svn_repository_test.rb"]
  s.test_files         = ["test/unit/plugin_test.rb", "test/unit/repositories/abstract_repository_test.rb", "test/unit/repositories/git_repository_test.rb", "test/unit/repositories/svn_repository_test.rb"]
  s.extra_rdoc_files   = ['README', 'CHANGELOG']
  
  s.add_dependency("activesupport", ["> 0.0.0"])
end