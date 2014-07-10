require 'active_support/all'
require 'extensions'
require 'flexhash'
require 'mathn'

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

class Object
  def try_dup()
    self.dup
  rescue
    self
  end
end

class Class
  def save_as(klass_name)
    Object.const_set(klass_name, self)
  end

  # Set class instance variable attributes, and see that the values get inherited by subclasses. Attribute readers are
  # also set up for object instances that copy it from the class.
  #
  # The values are `dup`ed if possible and simply handed over otherwise (when inheriting and instantiating).
  #
  # Note that this seems to behave very differently than active-support's `class_attribute` method- which seems to use
  # actual class-variables with all the problems they end up having. (of course I could have just been using
  # active-support's wrong).
  #
  # The only safety that keeps these from affecting class instance variables where they shouldn't is the naming
  # convention. Anything more clever than that and my ruby metaprogramming skills weren't up to snuff.
  #
  # Also, as you can surmise, it won't work if a class uses the `inherited` hook and fails to call super.
  #
  def class_attr_inheritable(attr_name, init_as=nil)
    self.class_eval("def self.#{attr_name};@__cai__#{attr_name} end")
    self.class_eval("def self.#{attr_name}=(v);@__cai__#{attr_name}=v end")
    self.send("#{attr_name}=", init_as) unless init_as.nil?
    self.class_eval("def #{attr_name};@#{attr_name} ||= self.class.#{attr_name}.try_dup end")
  end

  def inherited(subclass)
    instance_variables.each do |v|
      next unless v.to_s.starts_with?('@__cai__')
      new_val = self.instance_variable_get(v).try_dup
      subclass.instance_variable_set(v, new_val)
    end
  end
end

require 'proplist'
require 'nodus/nodes'
