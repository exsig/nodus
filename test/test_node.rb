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
      input  :x, Integer
      output :y, Integer
      def initialize(size=1) @buff = Array.new(size, nil) end
      def start() y << (@buff << x.receive).shift; :start end
    end
  end

  after do
    remove_class LagNode
  end


  # it 'can act like a lazy enumerable' do
  #   5.times.node(LagNode.new).to_a.must_equal [nil, 0, 1, 2, 3]
  # end

  # it 'requires correct input' do

  # end

end
