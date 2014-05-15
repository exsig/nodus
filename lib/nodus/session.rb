# Initially created by:
#   * any BufferedStream when it is the originating point of a session,
#   * any root-node generator
#   * a processing node if it is given token-less data (wraps in a default anon session)
#   * a processing node that explicitly creates a new signal
module Nodus
  # * longevity
  # * (abstract) data-sources
  # * (abstract) end-points
  # * node-graph
  #
  # instances:
  #  - attach to specific data-sources + starting points
  #  - attach to specific end-point(s)
  #  - gets its own session uids etc.
  #  - instances of its own nodes/sources/sinks
  class Session

  end


end
