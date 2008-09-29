Gem::Specification.new do |s|
  s.name               = "sashimi"
  s.version            = "0.2.1"
  s.date               = "2008-09-29"
  s.summary            = "Rails plugins manager"
  s.author             = "Luca Guidi"
  s.email              = "guidi.luca@gmail.com"
  s.homepage           = "http://lucaguidi.com/pages/sashimi"
  s.description        = "Sashimi is a local repository for Rails plugins."
  s.has_rdoc           = true
  s.rubyforge_project  = %q{sashimi}
  s.executables        = [ 'sashimi' ]
  s.files              = ["CHANGELOG", "MIT-LICENSE", "README", "Rakefile", "bin/sashimi",
    "lib/sashimi.rb", "lib/sashimi/commands.rb", "lib/sashimi/core_ext.rb",
    "lib/sashimi/core_ext/array.rb", "lib/sashimi/core_ext/class.rb",
    "lib/sashimi/core_ext/string.rb", "lib/sashimi/plugin.rb", "lib/sashimi/repositories.rb",
    "lib/sashimi/repositories/abstract_repository.rb", "lib/sashimi/repositories/git_repository.rb",
    "lib/sashimi/repositories/svn_repository.rb", "lib/sashimi/version.rb", "sashimi.gemspec",
    "setup.rb", "test/test_helper.rb", "test/unit/core_ext/array_test.rb",
    "test/unit/core_ext/class_test.rb", "test/unit/core_ext/string_test.rb",
    "test/unit/plugin_test.rb", "test/unit/repositories/abstract_repository_test.rb",
    "test/unit/repositories/git_repository_test.rb", "test/unit/repositories/svn_repository_test.rb",
    "test/unit/version_test.rb"]
  s.test_files         = ["test/unit/core_ext/array_test.rb", "test/unit/core_ext/class_test.rb",
    "test/unit/core_ext/string_test.rb", "test/unit/plugin_test.rb",
    "test/unit/repositories/abstract_repository_test.rb",
    "test/unit/repositories/git_repository_test.rb", "test/unit/repositories/svn_repository_test.rb",
    "test/unit/version_test.rb"]
  s.extra_rdoc_files   = ['README', 'CHANGELOG']
  
  s.add_dependency("activesupport", ["> 0.0.0"])
end