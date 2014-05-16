require 'active_support/all'

module Nodus
  @_error_msg_map = {}

  def self.def_exception(sym, msg, superclass=RuntimeError)
    klass = Class.new(superclass)
    Nodus.const_set(sym, klass)
    @_error_msg_map[klass] = msg
  end

  def self._error_msg(klass) @_error_msg_map[klass] end
end

def error(klass, *args) raise klass, sprintf(*([Nodus._error_msg(klass)] + args)) end

require 'nodus/version'
require 'nodus/state_machine'
require 'nodus/actor'

require 'nodus/token'
require 'nodus/signal_path'
require 'nodus/node'
require 'nodus/signal'
require 'nodus/session'

