require 'helper'
require 'nodus/node'
include Nodus
#class NodesTest < MiniTest::Unit::TestCase
#  def test_node
#    # 
#
#
#  end
#
#  def test_lag_node
#    lag = Nodus::Node::Lag.new(1)
#    assert_equal  nil, lag.next(1)
#    assert_equal  1,   lag.next(2)
#    assert_equal  2,   lag.next(-1)
#    assert_equal -1,   lag.next(2)
#
#    lag = Nodus::Node::Lag.new(5)
#    5.times{|n| lag.next n}
#    assert_equal 0, lag.next(5)
#  end
#
#
#end
#
#
#class BufferedStreamTest < MiniTest::Unit::TestCase
#
#  class BSTest < Nodus::BufferedStream
#    
#  end
#
#  def test_temporary_buffered_stream
#    b = BSTest.new
#    #b << 
#  end
#end

describe Node do
#  before do
#    class LagNode < Node
#      input  :a, Integer
#      output :b, Integer
#      def parameterize(size=1) @buff = Array.new(size, nil) end
#      def start() b << (@buff << a.receive).shift; :start end
#    end
#  end

  after do
    # remove_class LagNode
    remove_class :ExampleNode
  end

  it 'allows class-level ports to be defined' do
    class ExampleNode < Node
      input  :x
      input  :y, Integer
      input  :z, Float, "The ~z~"
      output :h
      output :i, Array
      output :j, Integer, "The ~j~"
      state_method :start
      def start; :done end
    end

    s = ExampleNode.new
    s.inputs.size.must_equal        3
    s.outputs.size.must_equal       3
    s.inputs.first.name.must_equal  :x
    s.outputs.first.name.must_equal :h
  end

  it 'merges class and instance-level ports' do
    class ExampleNode < Node
      input  :x, Integer
      output :y, Integer
      def parameterize
        input  :m
        output :n, Float
      end
      state_method :start
      def start; :done end
    end

    s = ExampleNode.new

    s.inputs.size.must_equal  2
    s.outputs.size.must_equal 2

    s.inputs.map{|i|  i.name }.sort.must_equal [:m, :x]
    s.outputs.map{|i| i.name }.sort.must_equal [:n, :y]
  end

  it 'detects duplicate port names' do
    class ExampleNode < Node
      input  :x
      output :x
    end
    ->{ ExampleNode.new }.must_raise RuntimeError
  end

  it 'requires a start state' do
    class ExampleNode < Node
      input :x
    end
    ->{ ExampleNode.new.thread.join }.must_raise NoMethodError
  end

  it 'stays alive if it has work to do' do
    class ExampleNode < Node
      input  :x
      output :y
      state  :start
      def start; sleep 1; :start end
    end

    s = ExampleNode.new
    sleep 0.25
    Thread.pass
    s.alive?.must_equal true
  end

  it 'is no longer alive if it has finished' do
    class ExampleNode < Node
      output :y
      state  :start
      def start; :done end
    end
    s = ExampleNode.new
    sleep 0.25
    Thread.pass
    s.alive?.must_equal false
  end

  it 'has methods defined for input ports' do
    class ExampleNode < Node
      input :x
      state :start
      def parameterize; input :y end
      def start; sleep 1; :start end
    end

    s = ExampleNode.new
    s.respond_to?(:x).must_equal true
    s.respond_to?(:y).must_equal true
    s.respond_to?(:z).must_equal false
  end

  it 'has methods defined for output ports' do
    class ExampleNode < Node
      output :x
      state :start
      def parameterize; output :y end
      def start; sleep 1; :start end
    end

    s = ExampleNode.new
    s.respond_to?(:x).must_equal true
    s.respond_to?(:y).must_equal true
    s.respond_to?(:z).must_equal false
  end

  it 'does not leak port methods to class' do
    class ExampleNode < Node
      output :y
      state :start
      def parameterize(has_x)
        input :x if has_x
      end
      def start; sleep 1; :start end
    end

    s1 = ExampleNode.new(true)
    s2 = ExampleNode.new(false)
    s1.respond_to?(:x).must_equal true
    s2.respond_to?(:x).must_equal false
  end

  it 'has correct port types' do
    class ExampleNode < Node
      input :x
      def parameterize; output :y end
      state :start
      def start; sleep 1; :start end
    end
    s = ExampleNode.new
    s.x.must_be_kind_of InputNodePort
    s.y.must_be_kind_of OutputNodePort
  end


  #--------------- Port accessability -------------

  it 'allows external data into input port' do
    class ExampleNode < Node
      input(:x); output(:y); state(:start)
      def start; pass; :start end
    end
    s = ExampleNode.new
    s.x.send(1).must_equal s.x
    (s.x << 1).must_equal  s.x
  end

  it 'disallows external data into output port' do
    class ExampleNode < Node
      input(:x); output(:y); state(:start)
      def start; pass; :start end
    end
    s = ExampleNode.new
    ->{ s.y.send(123)}.must_raise RuntimeError
    ->{ s.y << 123   }.must_raise RuntimeError
  end

  it 'allows internal data into output port' do
    class ExampleNode < Node
      input(:x); output(:y); state(:start)
      def start; y << 123; :done end
    end
    ExampleNode.new.value.must_equal :normal_exit
  end

  it 'disallows internal data into output port' do
    class ExampleNode < Node
      input(:x); output(:y); state(:start)
      def start; x << 123; :done end
    end
    ->{ ExampleNode.new.value }.must_raise RuntimeError
  end

  it 'allows external data out of output port' do
    class ExampleNode < Node
      input(:x); output(:y); state(:start)
      def start; y << 123; sleep 1; :start end
    end
    ExampleNode.new.y.receive.must_equal 123
  end

  it 'disallows external data out of input port' do
    class ExampleNode < Node
      input(:x); output(:y); state(:start)
      def start; y << 123; sleep 1; :start end
    end
    ->{ExampleNode.new.x.receive}.must_raise RuntimeError
  end

  it 'disallows internal data from output port' do
    class ExampleNode < Node
      input(:x); output(:y); state(:start)
      def start; y.receive; :start end
    end
    ->{ExampleNode.new.value}.must_raise RuntimeError
  end

  it 'passthrough- allows internal data from input port' do
    class ExampleNode < Node
      input(:x); output(:y); state(:start)
      def start; y << x.receive; :start end
    end
    s = ExampleNode.new
    s.x << 123
    s.y.receive.must_equal 123
  end


  #-----------------------------------------------------------



end
