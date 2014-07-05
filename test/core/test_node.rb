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
    StreamPort.new(nil, :str)[1].must_be_nil
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

module MiniTest::Assertions
  def assert_valid_binding(obj)
    msg = "expected a #{obj} to be a valid binding [input_port, output_port]"
    assert Array === obj, msg
    assert obj[0].kind_of?(InputBranchPort), msg
    assert obj[1].kind_of?(OutputBranchPort), msg
  end
end
Object.infect_an_assertion :assert_valid_binding, :must_be_valid_binding, :only_one_argument

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

    class NodeC < Node
      def initialize(*)
        super
        input  :b_input
        output :b_output
      end
    end
    @a = NodeA[:the_a]
    @b = NodeB[:the_b]
    @c = NodeC[:the_c]
  end

  after do
    @a = @b = @c = nil
    remove_class :NodeA
    remove_class :NodeB
    remove_class :NodeC
  end

  it 'can be accessed easily to any depth' do
    @a.inputs.a_input.must_be_kind_of         InputStreamPort
    @a.inputs.a_input.main.must_be_kind_of    InputBranchPort
    @b.outputs.b_output.must_be_kind_of       OutputStreamPort
    @b.outputs.b_output2.main.must_be_kind_of OutputBranchPort
  end

  it 'gives good full names' do
    @a.inputs.a_input.full_name.must_equal         'the_a.inputs.a_input'
    @a.inputs.a_input.main.full_name.must_equal    'the_a.inputs.a_input.main'
    @b.outputs.b_output.full_name.must_equal       'the_b.outputs.b_output'
    @b.outputs.b_output2.main.full_name.must_equal 'the_b.outputs.b_output2.main'
  end

  it 'exposes correct binding side depending on type' do
    @a.inputs.a_input.must_respond_to :listen_to
    @a.inputs.a_input.wont_respond_to :add_subscriber
    @b.outputs.b_output.must_respond_to :add_subscriber
    @b.outputs.b_output.wont_respond_to :listen_to
  end

  it 'can be bound together from input perspective' do
    @a.inputs.a_input.listen_to(@b.outputs.b_output).must_be_valid_binding
  end

  it 'can be bound together from output perspective' do
    @b.outputs.b_output.add_subscriber(@a.inputs.a_input).must_be_valid_binding
  end

  it 'will not allow an input to be bound to more than one' do
    binding1 = @a.inputs.a_input.listen_to(@b.outputs.b_output)
    ->{@a.inputs.a_input.listen_to(@b.outputs.b_output2)}.must_raise RuntimeError
  end

  it 'will not allow an input to be bound to more than one (output perspective)' do
    binding1 = @b.outputs.b_output.add_subscriber(@a.inputs.a_input)
    ->{@a.inputs.a_input.listen_to(@b.outputs.b_output2)}.must_raise RuntimeError
    ->{@b.outputs.b_output2.add_subscriber(@a.inputs.a_input)}.must_raise RuntimeError
  end


  it 'ignores duplicate binding actions' do
    binding1 = @a.inputs.a_input.listen_to(@b.outputs.b_output)
    binding2 = @a.inputs.a_input.listen_to(@b.outputs.b_output)
    binding1.must_equal binding2
  end

  it 'ignores duplicate binding actions (output perspective)' do
    binding1 = @b.outputs.b_output.add_subscriber(@a.inputs.a_input)
    binding2 = @b.outputs.b_output.add_subscriber(@a.inputs.a_input)
    binding1.must_equal binding2
    @b.outputs.b_output.main.subscribers.size.must_equal 1
  end

  it 'allows binding at all levels of detail' do
    input_ports  = [@a, @a.inputs.a_input, @a.inputs[:a_input], @a.inputs.a_input.main, @a.inputs.a_input[:main],
                    @a.inputs.a_input[0], @a.inputs[0][0], @a.inputs[0]]
    output_ports = [@c, @c.outputs.b_output, @c.outputs[:b_output], @c.outputs.b_output.main,
                    @c.outputs.b_output[:main], @c.outputs.b_output[0], @c.outputs[0][0], @c.outputs[0]]

    input_ports.each do |ip|
      output_ports.each do |op|
        ip.listen_to(op).must_be_valid_binding
        op.add_subscriber(ip).must_be_valid_binding
      end
    end
  end


  # TODO: don't know if it should check for cycles when the objects are bound or at some point later when they are run
  #       instead...
end
