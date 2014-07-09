
# Properties of properties (such as required, default, type, etc.)
class PropSet
  # TODO: this pattern with inverses & defaults is being repeated a lot. Abstract it.
  class << self
    def inherited(subclass)
      subclass.inverses = inverses.dup
      subclass.defaults = defaults.dup
    end

    def inverses() @inverses ||= {} end
    def defaults() @defaults ||= {} end  # Don't confuse this with the property's default- it's the property's property's default (e.g., `required` defaults to false, or `default` defaults to nil)
    attr_writer :inverses, :defaults

    protected def inverse(kvpairs) inverses.merge!(kvpairs) end # TODO: verify that keys aren't values and that there are no duplicate values
    protected def default(kvpairs) defaults.merge!(kvpairs) end
  end

  def inverses() @inverses ||= self.class.inverses.dup end
  def defaults() @defaults ||= self.class.defaults.dup end

  def initialize(*opts)
    @data = {}
    merge_opts(*opts)
  end

  def inspect() "#<PropSet #{@data.inspect}>" end
  def to_hash() @data end

  def merge_opts(*opts)
    opts = [opts].flatten.reduce({}){|h,o| Hash === o ? h.merge(o) : h.merge({o.to_sym => true})}
    opts.each do |k, v|
      k_str = k.to_s
      k_sym = k.to_sym
      if k_str.starts_with?('no_')
        if v = true
          k_to_remove = k_str[3..-1].to_sym
          @data.delete(k_to_remove)
          @data.delete(inverses[k_to_remove])
        else
          error ArgumentError, "Parameter aspects that start with 'no_' are for unsetting that aspect of the property. For example, `no_default: true`- Always expecting 'true' as the value."
        end
      else
        if inverses[k_sym]
          error ArgumentError, "Expected true or false value for #{k_sym} aspect of property #{@name}" unless v == !!v
          v = !v
          k_sym = inverses[k_sym]
        end
        @data[k_sym] = v
      end
    end
  end

  def method_missing(m, *a, &b)
    # TODO: check @data for key before checking it for respond_to to solve future problems like this :default hack
    return @data.send(m, *a, &b) if @data.respond_to?(m) && ![:default,:default=].include?(m.to_sym)
    case m.to_s
    when /^(.+)=$/      then merge_opts($1 => (a.size == 1 ? a[0] : a))
    when /^has_(.+)\?$/ then @data.has_key?($1.to_sym) || @data.has_key?(inverses[$1.to_sym])
    when /^(.+)\?$/     then !!val_for($1)
    else                     val_for(m)
    end
  end

  def val_for(key)
    key = key.to_sym
    rev = inverses.has_key?(key)
    key = inverses[key] if rev
    val = nil
    if @data.has_key?(key) || defaults.has_key?(key)
      val = @data.has_key?(key) ? @data[key] : defaults[key]
      val = !val if rev
    end
    val
  end

  # When the property is given a value specify (via overriding this method) anything special that needs to happen to the
  # PropSet instance.
  def realize(val) self.value = val end
  def realized?()  self.has_value?  end
  def realized
    return self.value   if self.has_value?
    return self.default if self.has_default?
    nil
  end
end

class PropList < Delegator
  def initialize(propclass=PropSet)
    @propclass = propclass
    @data      = {}
    super(@data)
  end

  def __getobj__()  @data                    end
  def __setobj__(o) @data = o                end
  def [](k)         @data[k.to_sym]          end
  def dup() Marshal.load(Marshal.dump(self)) end

  def realize(name, value) add(name).tap{|pset| pset.realize(value)} end
  alias_method :[]=, :realize

  def add_name_opts(name_and_opts) name = name_and_opts.shift; add(name, name_and_opts) end
  alias_method :<<, :add_name_opts


  def add(name, *opts)
    name = name.to_sym
    if     @data[name] && opts.present? then @data[name].merge_opts(opts)
    elsif !@data[name]                  then @data[name] = @propclass.new(opts, name: name) end
    @data[name]
  end

  def merge(newer_proplist)
    @data.merge(newer_proplist){|key, oldval, newval| oldval.merge_opts(newval.to_hash)}
  end
  alias_method :+, :merge

  def method_missing(m, *a, &b)
    return @data[m.to_sym] if @data.has_key?(m.to_sym)
    return @data.send(m, *a, &b) if @data.respond_to?(m)
    super
  end
end
