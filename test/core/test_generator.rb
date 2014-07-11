require_relative '../helper.rb'
include Nodus::Nodes

class GenClass; def each() loop{yield(rand)} end end

class GenClassWithRange
  def initialize(range)
    @range = range
  end
  def each() loop{yield(rand(@range))} end
end

describe Nodus::Nodes::Generator do
  it 'can be created from a class with an "each" method' do
    g = Generator[:mygen, GenClass]
    g.must_be_a_node
    g.title.must_equal  :mygen
    g.kernel.must_equal GenClass
  end

  it 'infers parameters from the class initialization' do
    g = Generator[:mygen, GenClassWithRange]
    g.must_be_a_node
    g.parameters.keys.include?(:range).must_be_true
    g.parameters.range.required?.must_be_true
  end
end
