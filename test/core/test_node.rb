require_relative '../helper.rb'
include Nodus

describe Nodus::Node do
  after do
    remove_class :ExampleNode
  end

  it 'allows class-level stream-ports to be defined' do
    class ExampleNode < Node
      input  :x
      input  :y
      input  :z, "The ~z~"
      output :h
      output :i
      output :j, "The ~j~"
    end

    s = ExampleNode.new
    s.inputs.size.must_equal        3
    s.outputs.size.must_equal       3
    s.inputs.first.name.must_equal  :x
    s.outputs.first.name.must_equal :h
  end

  it 'merges class and instance-level stream-ports' do
    class ExampleNode < Node
      input  :x
      output :y
      def initialize(*)
        input  :m
        output :n
        super
      end
    end

    s = ExampleNode.new

    s.inputs.size.must_equal  2
    s.outputs.size.must_equal 2

    s.inputs.map{|i|  i.name }.sort.must_equal [:m, :x]
    s.outputs.map{|i| i.name }.sort.must_equal [:n, :y]
  end

  it 'allows and tracks duplicate port names' do
    class ExampleNode < Node
      input  :a
      input  :x
      input  :x
      output :b
      output :x
      output :x
      def initialize(*)
        input  :x
        output :x
        super
      end
    end

    s = ExampleNode.new

    s.inputs.size.must_equal  4
    s.outputs.size.must_equal 4

    s.inputs.map{|i|  i.name }.sort.must_equal [:a, :x, :x, :x]
    s.outputs.map{|i| i.name }.sort.must_equal [:b, :x, :x, :x]
  end
end

