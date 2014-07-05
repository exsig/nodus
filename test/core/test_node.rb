require_relative '../helper.rb'
include Nodus

describe Nodus::StreamPort do
  it 'can be created with just a name' do
    StreamPort.new(nil, :the_stream).must_be_instance_of StreamPort
  end

  it 'has a main branch by default' do
    StreamPort.new(nil, :str).main.must_be_kind_of   BranchPort
    StreamPort.new(nil, :str)[:main].must_be_kind_of BranchPort
    StreamPort.new(nil, :str)[0].must_be_kind_of     BranchPort
    StreamPort.new(nil, :str)[1].must_equal          nil
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
      input  :z
      output :h
      output :i
      output :j
    end

    s = ExampleNode.new
    s.inputs.size.must_equal        3
    s.outputs.size.must_equal       3
    s.inputs.first.name.must_equal  :x
    s.outputs.first.name.must_equal :h
  end

  it 'allows class-level stream-ports to be multi-defined' do
    class ExampleNode < Node
      input  :x, :y, :z
      output :h, :i, :j
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

  it 'allows looking up ports by name' do
    class ExampleNode < Node

    end
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
      input :the_input, :a
      output :and_the_output, :b
    end

    s = ExampleNode.new
    s.inputs[:the_input].must_be_kind_of StreamPort
    s.outputs[/output/].name.must_equal :and_the_output
  end

  it 'groups matching ports into an array' do
    class ExampleNode < Node
      input :a, :a, :b
    end

    s = ExampleNode.new
    i = s.inputs[:a]
    i.must_be_kind_of Array
    i.size.must_equal 2
    i[0].must_be_kind_of StreamPort
    i[0].name.must_equal :a
    i[1].must_be_kind_of StreamPort
    i[1].name.must_equal :a
  end
end

describe 'Node ports' do
  before do
    class NodeA < Node
      input  :a_input
      output :a_output
    end

    class NodeB < Node
      def initialize(*)
        super
        input  :b_input
        output :b_output
        output :b_output2
      end
    end

    @a = NodeA[:the_a]
    @b = NodeB[:the_b]
  end

  after do
    @a = @b = nil
    remove_class :NodeA
    remove_class :NodeB
  end

  it 'can be bound together' do
    a,b = @a.inputs.a_input.listen_to(@b.outputs.b_output)
    a.must_be_kind_of InputBranchPort
    b.must_be_kind_of OutputBranchPort
    a.wont_equal      b
  end

  it 'will not allow an input to be bound to more than one' do
    binding1 = @a.inputs.a_input.listen_to(@b.outputs.b_output)
    ->{@a.inputs.a_input.listen_to(@b.outputs.b_output2)}.must_raise RuntimeError
  end

  it 'ignores duplicate binding actions' do
    binding1 = @a.inputs.a_input.listen_to(@b.outputs.b_output)
    binding2 = @a.inputs.a_input.listen_to(@b.outputs.b_output)
    binding1.must_equal binding2
  end

end
