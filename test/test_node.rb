require 'helper'
require 'nodus/node'
include Nodus

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
