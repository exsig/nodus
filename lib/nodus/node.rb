module Nodus
  class NodePort
    attr_accessor :name, :kind, :desc
    def initialize(name, kind=Integer, desc=nil)
      @name = name.to_s.to_sym
      @kind = kind
      @desc = desc
    end
  end

  class Node
    include Nodus::StateMachine

    def self.c_inputs()  @c_inputs  ||= [] end
    def self.c_outputs() @c_outputs ||= [] end
    def self.input (sym, kind=Integer, desc=nil) c_inputs  << NodePort.new(sym, kind, desc) end
    def self.output(sym, kind=Integer, desc=nil) c_outputs << NodePort.new(sym, kind, desc) end

    def initialize(*args, &block)
      @inputs  = [] + self.class.c_inputs
      @outputs = [] + self.class.c_outputs
      parameterize(*args, &block)
    end

    def parameterize() :redefine_me end


    def input(sym, kind=Integer, desc=nil)
      @inputs << NodePort.new(sym, kind, desc)
    end

    def output(sym, kind=Integer, desc=nil)
      @outputs << NodePort.new(sym, kind, desc)
    end

    def inputs() @inputs end
    def outputs() @outputs end
  end
end










# in-ports
# out-ports
# enumable
# actorable
# generator

#  module Node
#    # Goals
#    #   - classes can act in a simple manner or essentially as actors- so for example, FDiff uses the Lag as well as
#    #     sub-classed FDiffs. It may need to be its own actor but Lag and its subclasses shouldn't have to be their own
#    #     threads. In another case though, Lag may need to be on its own thread.
#    # Notes
#    #   - Lazy enum more appropriate for the "core" nodes?
#    #   - Ruby stream mechanisms?
#    class Lag
#      def initialize(size) @buff = Array.new(size, nil) end
#      def next(x) (@buff << x).shift end
#    end
#
#    class FDiff
#      def initialize(lag=1, cap=4)
#        @lag = Lag.new(lag)
#        @cap = cap
#        @next_order = FDiff.new(1, @cap - 1) if @cap > 1
#      end
#
#      def next(x)
#        prev = @lag.next(x)
#        diff = (prev.nil? || x.nil?) ? nil : x - prev
#        res  = [diff]
#        res += @next_order.next(diff) if @cap > 1
#        res
#      end
#    end
#  end


# module Nodus
#   module Random
#     class Uniform
#       include Enumerable
# 
#       def initialize(range=nil, seed=nil)
#         @seed  = seed || ::Random.new_seed
#         @range = range || 1.0
#         @prng  = ::Random.new(@seed)
#       end
# 
#       def each
#         loop do
#           yield @prng.rand(@range)
#         end
#       end
#     end
#   end
# end

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
