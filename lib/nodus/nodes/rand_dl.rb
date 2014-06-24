# Discrete Laplace (very simple version- symmetrical parameterized by geometric function's 'p')
#
# See http://www.ijmsi.org/Papers/Volume.2.Issue.3/K0230950102.pdf for a better version with skew and well-defined
# properties.
#
module Nodus
  module Nodes
    module Random
      class DL < Node
        state_method :start
        output :y

        def parameterize(p=0.4, seed=nil)
          @p = p
          @seed = seed || ::Random.new_seed
          @prng = ::Random.new(@seed)
        end

        private def geom
          i = 0
          loop do
            r = @prng.rand
            return i if r < @p
            i += 1
          end
        end

        def start
          y << (geom - geom)
          :start
        end
      end
    end
  end
end
