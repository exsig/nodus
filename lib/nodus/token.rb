


# - [ ] modification graph
# - [ ] timings in graph
# - [ ] current-data per thread/context
# - [ ] data appending
# - [ ] data freezing/locking per thread/context
#

module Nodus
  def self.timestamp
    # Use a better Process.clock_gettime time instead (not supported by rubinius yet)
    Time.now
  end

  # TODO: probably a token wrapper which designates the active data of the underlying token. This way the token can be
  # the same token across all parallel streams, while each parallel stream will have it's own temporary view of it at
  # each step...

  class Token
    attr_reader :seq_id, :stream, :timings
    def initialize(stream, seq_id)
      @stream  = stream
      @seq_id  = seq_id
      @timings = {generated: Nodus.timestamp}
      @data    = {}

    end
  end
end
