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
require 'ffaker'
require 'randexp'
require 'minitest'
require 'minitest/reporters'
require 'minitest/spec'
require 'minitest/autorun'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'nodus'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

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
I18n.enforce_available_locales = false

include Faker


module RandomGen
  def rand_poisson(lmbda=10)
    # Poisson distribution with mean & variance of lmda- via knuth's simple algorithm
    el = Math.exp(- lmbda); k=0; p=1
    loop do
      k += 1; p *= rand
      return k - 1 if p <= el
    end
  end

  def rand_times(lmbda=10, &block)
    k = rand_poisson(lmbda)
    if block_given? then k.times.map(&block)
    else k.times end
  end

  def rand_word
    len = rand_poisson
    return '' if len == 0
    /\w{#{len}}/.gen
  end

  def random_path
    '/' + rand_times{rand_word}.join('/')
  end

  def random_datetime
    ::Faker::Time.date(series: [])[0]
  end
end

include RandomGen

class Module
  include Minitest::Spec::DSL
end

def remove_class(klass)
  const = klass.to_s.to_sym
  Object.send(:remove_const, const) if Object.send(:const_defined?, const)
end


module MiniTest::Assertions
  def assert_true(obj)   assert obj==true,  "expected '#{obj}' to be true"  end
  def assert_false(obj)  assert obj==false, "expected '#{obj}' to be false" end
  def assert_truthy(obj) assert obj,        "expected '#{obj}' to be something other than nil or false"  end
  def assert_falsy(obj)  refute obj,        "expected '#{obj}' to be nil or false" end
end
Object.infect_an_assertion :assert_true,   :must_be_true,   :only_one_argument
Object.infect_an_assertion :assert_false,  :must_be_false,  :only_one_argument
Object.infect_an_assertion :assert_truthy, :must_be_truthy, :only_one_argument
Object.infect_an_assertion :assert_falsy,  :must_be_falsy,  :only_one_argument



#----------------------------------- NODUS SPECIFIC ---------------------------------------------------------

module MiniTest::Assertions
  def assert_kind_of_node(obj)
    assert obj.kind_of_node?, "expected #{obj} to be a class descended from Node"
  end
end
Object.infect_an_assertion :assert_kind_of_node,
                           :must_be_a_node,
                           :only_one_argument
