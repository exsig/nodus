require 'helper'

class NodesTest < MiniTest::Unit::TestCase
  def test_node
    # 


  end

  def test_lag_node
    lag = Nodus::Node::Lag.new(1)
    assert_equal  nil, lag.next(1)
    assert_equal  1,   lag.next(2)
    assert_equal  2,   lag.next(-1)
    assert_equal -1,   lag.next(2)

    lag = Nodus::Node::Lag.new(5)
    5.times{|n| lag.next n}
    assert_equal 0, lag.next(5)
  end


end
