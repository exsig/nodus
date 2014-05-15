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
  before do
    class LagNode < Node
      input  :a, Integer
      output :b, Integer
      def parameterize(size=1) @buff = Array.new(size, nil) end
      def start() b << (@buff << a.receive).shift; :start end
    end
  end

  after do
    remove_class LagNode
  end

  it 'allows class-level ports to be defined' do
    s = LagNode.new
    s.inputs.size.must_equal        1
    s.outputs.size.must_equal       1
    s.inputs.first.must_be_kind_of  NodePort
    s.outputs.first.must_be_kind_of NodePort
    s.inputs.first.name.must_equal  :a
    s.outputs.first.name.must_equal :b
  end

  it 'merges class and instance-level ports' do
    class Subject < Node
      input  :x, Integer
      output :y, Integer
      def parameterize
        input :m
        output :n
      end
    end

    s = Subject.new

    s.inputs.size.must_equal  2
    s.outputs.size.must_equal 2

    s.inputs.map{|i|  i.name }.sort.must_equal [:m, :x]
    s.outputs.map{|i| i.name }.sort.must_equal [:n, :y]

    remove_class Subject
  end

  # it 'can act like a lazy enumerable' do
  #   5.times.node(LagNode.new).to_a.must_equal [nil, 0, 1, 2, 3]
  # end

  # it 'requires correct input' do

  # end

end
