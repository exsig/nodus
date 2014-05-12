require 'nodus/version'
module Nodus
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
end

#require 'nodus/random'
require 'nodus/buffered_stream'
