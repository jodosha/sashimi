Gem::Specification.new do |s|
  s.name               = "sashimi"
  s.version            = "0.1.7"
  s.date               = "2008-06-23"
  s.summary            = "Rails plugins manager"
  s.author             = "Luca Guidi"
  s.email              = "guidi.luca@gmail.com"
  s.homepage           = "http://lucaguidi.com/pages/sashimi"
  s.description        = "Sashimi is a local repository for Rails plugins."
  s.has_rdoc           = true
  s.rubyforge_project  = %q{sashimi}
  s.executables        = [ 'sashimi' ]
  s.files              = Dir['**/*'].reject {|f| File.directory?(f)}.sort
  s.test_files         = Dir['test/**/*_test.rb'].reject {|f| File.directory?(f)}.sort
  s.extra_rdoc_files   = ['README', 'CHANGELOG']
  
  s.add_dependency("activesupport", ["> 0.0.0"])
end