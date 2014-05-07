require 'nodus/version'
module Nodus
  module Node
    class Lag
      def initialize(size) @buff = Array.new(size, nil) end
      def next(x) (@buff << x).shift end
    end

    class FDiff
      def initialize(lag=1, cap=4)
        @lag = Lag.new(lag)
        @cap = cap
        @next_order = FDiff.new(1, @cap - 1) if @cap > 1
      end

      def next(x)
        prev = @lag.next(x)
        diff = (prev.nil? || x.nil?) ? nil : x - prev
        res  = [diff]
        res += @next_order.next(diff) if @cap > 1
        res
      end
    end
  end
end
