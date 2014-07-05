require 'extensions'
require 'flexhash'

module Nodus
  SRCDIR  = File.dirname(__FILE__)
  @_error_msg_map = {}

  def self.def_exception(sym, msg, superclass=RuntimeError)
    klass = Class.new(superclass)
    Nodus.const_set(sym, klass)
    @_error_msg_map[klass] = msg
  end

  def self._error_msg(klass) @_error_msg_map[klass] end

  def self.const_missing(cname)
    m = "nodus/#{cname.to_s.underscore}"
    require m
    klass = const_get(cname)
    return klass if klass
    super
  end
end

def error(klass, *args)
  msg = Nodus._error_msg(klass)
  msg ||= args.shift
  raise klass, sprintf(*([msg] + args))
end

require 'nodus/node'
