$:.unshift 'lib'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the sashimi gem.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the sashimi gem.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Sashimi'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc 'Build and install the gem (useful for development purposes).'
task :install do
  require 'sashimi'
  system "rm sashimi-*.gem"
  system "gem build sashimi.gemspec"
  system "sudo gem uninstall sashimi"
  system "sudo gem install --local --no-rdoc --no-ri sashimi-#{Sashimi::VERSION::STRING}.gem"
end
