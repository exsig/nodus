require 'helper'
require 'nodus/node'
include Nodus

def ident_node(in_name=:x, out_name=:y)
  unless defined? IdentNode
    eval <<-CLASSDEF
        class IdentNode < Node
          state  :start
          def parameterize(in_name=:x, out_name=:y)
            input(@inp = in_name)
            output(@outp = out_name)
          end
          def start
            #output_ports[0] << input_ports[0].receive
            self.send(@outp) << self.send(@inp).receive
            return :start
          end
        end
      CLASSDEF
  end
  IdentNode.new(in_name, out_name)
end

describe Node do
  after do
    remove_class :ExampleNode
    remove_class :IdentNode
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
    ->{ ExampleNode.new }.must_raise DuplicatePortError
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
    ->{ s.y.send(123)}.must_raise OutputWriteError
    ->{ s.y << 123   }.must_raise OutputWriteError
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
    ->{ ExampleNode.new.value }.must_raise InputWriteError
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
    ->{ExampleNode.new.x.receive}.must_raise InputReadError
  end

  it 'disallows internal data from output port' do
    class ExampleNode < Node
      input(:x); output(:y); state(:start)
      def start; y.receive; :start end
    end
    ->{ExampleNode.new.value}.must_raise OutputReadError
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

  it 'passes data through as appropriate' do
    s = ident_node
    10.times do |i|
      s.x << i
      s.y.receive.must_equal i
    end

    10.times {|i| s.x << i }
    10.times {|i| s.y.receive.must_equal i }

    s.x << 123 << 321 << 456
    s.y.receive.must_equal 123
    s.y.receive.must_equal 321
    s.y.receive.must_equal 456
  end

  # TODO: several other tests revolving around the node status/death/restarts etc. and availability of ports etc.

  # TODO: test backlog-send-blocking functionality somehow...


  it "allows binding an output to an input" do
    s1 = ident_node
    s2 = ident_node
    s1.y | s2.x
    s1.x << 1 << 2 << 3
    s2.y.receive.must_equal 1
    s2.y.receive.must_equal 2
    s2.y.receive.must_equal 3
  end

  it 'sends backlog to a new bound peer' do
   # (even if there is a blocked send because the backlog is too big)
   s1 = ident_node(:x, :y)
   s2 = ident_node(:x2, :y2)
   nums = RandomGen.rand_times(4000).to_a
   Thread.new { nums.each{|n| s1.x << n } }
   sleep 0.1
   s1.y | s2.x2
   nums.each{|n| s2.y2.receive.must_equal n}
 end

end
