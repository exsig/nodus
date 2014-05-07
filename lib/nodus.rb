require 'nodus/version'
module Nodus
  module Node
    class Lag
      def initialize(size)
        @size = size
        @buff = @size > 1 ? Array.new(@size, nil) : nil
      end
      def next(x)
        if @size > 1 then res = @buff.shift; @buff << x
        else              res = @buff;       @buff  = x end
        res
      end
    end

    class FDiff
      def initialize(lag=1, cap=4)
        @lag = Lag.new(lag)
        @cap = cap
        @next_order = BackwardFiniteDiff.new(1, @cap - 1) if @cap > 1
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
