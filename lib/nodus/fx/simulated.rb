# Going to start out pretty dumb:
#   - constant (ignored) physical time-intervals
#   - slightly drifting spread
#   - discrete-laplace random walk on bid, with ask calculated from current spread (obviously isn't capturing bid vs ask
#     driving phenomena- or a number of other things)
#   - at the moment allowing the walk to go negative. fix when/if it becomes an issue (with some kind of attractor...)
#


module Nodus
  module FX
    class Simulated < Node
      def parameterize(initial_offset=1000, mean_spread=15)

      end
    end
  end
end
