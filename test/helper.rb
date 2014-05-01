require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'simplecov'
require 'minitest'
require 'minitest/unit'
require 'minitest/autorun'
require 'minitest/reporters'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'nodus'

class Reporter < Minitest::Reporters::BaseReporter
  def start
    super
    puts "#  AWESOME!"
    puts
  end
end

Minitest::Reporters.use! Minitest::Reporters::ProgressReporter.new

module SimpleCov::Configuration
  def clean_filters
    @filters = []
  end
end

SimpleCov.configure do
  clean_filters
  load_adapter 'test_frameworks'
end

ENV["COVERAGE"] && SimpleCov.start do
  add_filter "/.rvm/"
end

class MiniTest::Unit::TestCase
end
