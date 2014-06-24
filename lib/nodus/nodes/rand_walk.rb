# Essentially the equivalent of a running sum, to be run with some random generator


module Nodus
  module Nodes
    module Random
      class Walk < Node
        state_method :start
        output :y

        def parameterize(offset=1000, rgen=nil)
          @rgen = rgen || Random::DL.new
          @curr = offset
        end

        def start
          y << (@curr += @rgen.y.receive)
          :start
        end
      end
    end
  end
end
