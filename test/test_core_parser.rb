require_relative './helper.rb'
require 'pp'
describe Nodus::CoreParser do
  subject { Nodus::CoreParser.new }

  it "parses blank lines, whitespace, and comments" do
    subject.parse(%(  
    \t
    \v    \r
        # Just a comment
    \n
    #| this
       is a multiline comment  |#
    # oh yeah))
  end


end
