require 'active_support/all'
require 'pp'

module Nodus
  VFILE   = File.join(File.dirname(__FILE__),'..','VERSION')
  VERSION = File.exist?(VFILE) ? File.read(VFILE).strip : `git -C '#{File.dirname(__FILE__)}' describe --tags`.strip

  @_error_msg_map = {}

  def self.def_exception(sym, msg, superclass=RuntimeError)
    klass = Class.new(superclass)
    Nodus.const_set(sym, klass)
    @_error_msg_map[klass] = msg
  end

  def self._error_msg(klass) @_error_msg_map[klass] end
end

def error(klass, *args)
  msg = Nodus._error_msg(klass)
  msg ||= args.shift
  raise klass, sprintf(*([msg] + args))
end

require 'nodus/state_machine'
require 'nodus/actor'

require 'nodus/token'
require 'nodus/signal_path'
require 'nodus/node'
require 'nodus/signal'
require 'nodus/session'

