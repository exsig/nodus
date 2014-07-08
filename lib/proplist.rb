class PropSet
  # TODO: this pattern with inverses & defaults is being repeated a lot. Abstract it.
  class << self
    def inherited(subclass)
      subclass.inverses = inverses.dup
      subclass.defaults = defaults.dup
    end

    def inverses() @inverses ||= {} end
    def defaults() @defaults ||= {} end
    attr_writer :inverses, :defaults

    def inverse(kvpairs) inverses.merge!(kvpairs) end # TODO: verify that keys aren't values and that there are no duplicate values
    def default(kvpairs) defaults.merge!(kvpairs) end
  end

  def inverses() @inverses ||= self.class.inverses.dup end
  def defaults() @defaults ||= self.class.defaults.dup end

  def initialize(*opts)
    @data = {}
    merge_opts(*opts)
  end

  def inspect() "#<PropSet #{@data.inspect}>" end

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
    return @data.send(m, *a, &b) if @data.respond_to?(m)
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

  def to_hash() @data end
end

class PropList < Delegator
  def initialize(propclass=PropSet)
    @propclass = propclass
    @data      = {}
    super(@data)
  end

  def __getobj__()  @data                    end
  def __setobj__(o) @data = o                end
  def dup() Marshal.load(Marshal.dump(self)) end

  def <<(name_and_opts)
    name, opts = name_and_opts
    name = name.to_sym
    if @data[name] then @data[name].merge_opts(opts)
    else @data[name] = @propclass.new(opts, name: name) end
    self
  end

  def merge(newer_proplist)
    @data.merge(newer_proplist){|key, oldval, newval| oldval.merge_opts(newval.to_hash)}
  end
  alias_method :+, :merge
end
