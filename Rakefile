# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
require './lib/nodus/version.rb'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://guides.rubygems.org/specification-reference/ for more options
  gem.name        = "nodus"
  gem.homepage    = "http://github.com/exsig/nodus"
  gem.license     = "MIT"
  gem.summary     = "Kahn process network with more sophistication for pipelining and signal processing"
  gem.description = %Q{EXPERIMENTAL. A form of data-flow programming based loosely on Kahn Process Networks. Will allow
                       for setting up operational components that can be pipelined together in a graph. Assumes all
                       components (nodes) are 'online' algorithms with more or less steady-state resource utilization
                       for continuous streams of data.}.gsub(/\s+/,' ')
  gem.email       = "joseph.wecker@exsig.com"
  gem.authors     = ["Joseph Wecker"]
  gem.version     = Nodus::VERSION

  # (dependencies are defined in the Gemfile)
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

desc "Code coverage detail"
task :simplecov do
  ENV['COVERAGE'] = "true"
  Rake::Task['test'].execute
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "nodus #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
