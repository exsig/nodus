require_relative '../helper.rb'
include Nodus

describe Nodus::StreamPort do
  it 'can be created with just a name' do
    StreamPort.new(:the_stream).must_be_instance_of StreamPort
  end

  it 'has a main branch by default' do
    StreamPort.new(:str).main.must_be_kind_of   BranchPort
    StreamPort.new(:str)[:main].must_be_kind_of BranchPort
    StreamPort.new(:str)[0].must_be_kind_of     BranchPort
    StreamPort.new(:str)[1].must_equal          nil
  end
end

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


  it 'gets created with the class brackets' do
    Node[].must_be_kind_of Node
  end

  it 'automatically lets descendants use bracket creation' do
    class ExampleNode < Node; end
    ExampleNode[].must_be_instance_of ExampleNode
  end

  it 'passes creation parameters to bracket notation' do
    class ExampleNode < Node
      attr_reader :a, :b
      def initialize(a,b)
        @a, @b = a, b
      end
    end

    ExampleNode[5,6].b.must_equal 6
  end


  it 'allows queries against inputs and outputs' do
    class ExampleNode < Node

    end
  end
end

