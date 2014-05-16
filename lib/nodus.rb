require 'active_support/all'
require 'e2mmap'

module Nodus
  module Errors
    extend Exception2MessageMapper
    alias error Raise
    class NodeError < ThreadError; end
  end
end

require 'nodus/version'
require 'nodus/state_machine'
require 'nodus/actor'

require 'nodus/token'
require 'nodus/signal_path'
require 'nodus/node'
require 'nodus/signal'
require 'nodus/session'

