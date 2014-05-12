module Nodus
  module Random
    class Uniform
      include Enumerable

      def initialize(range=nil, seed=nil)
        @seed  = seed || ::Random.new_seed
        @range = range || 1.0
        @prng  = ::Random.new(@seed)
      end

      def each
        loop do
          yield @prng.rand(@range)
        end
      end
    end
  end
end

#  * Implied indexing/context object
#  * 


#module Nodus
#  class RandomUniform < Nodus::Node
#    out_port      :y
#    initial_state :main
#    def parameterize(range=1.0, seed=nil)
#      @seed  = seed  || ::Random.new_seed
#      @range = range || 1.0
#      @prng  = ::Random.new(@seed)
#    end
#
#    def main
#      y.emit @prng.rand(@range)
#    end
#  end
#end


#  src = Nodus::RandomUniform.new
#  
#  
#  sources = [:oanda, :truefx].map{|data_source| 
#  
#  [:oanda, :truefx].map do |source_name|
#    Nodus::Accumulator.new do |acc|
#      acc.source = Nodus::FXSource[source_name]
#      acc.

