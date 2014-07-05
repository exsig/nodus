# Like a combination of HashWithIndifferentAccess, OpenStruct, plus it takes an integer and tries looking it up
# positionally. (bleh, like php's but a little more buggy. I know I know- but it's for a very specific purpose).
#
# Mostly cribbed from rubinius's ostruct: https://github.com/rubysl/rubysl-ostruct/blob/2.0/lib/rubysl/ostruct/ostruct.rb
# with just the [] access function changed and method_missing changed so it delegates unfound things to the underlying
# table.

class FlexHash

  def self.[](*arr_const)
    self.new(arr_const.flatten)
  end

  def initialize(constructor=nil)
    @table = {}
    if constructor.respond_to?(:each_pair)
      constructor.each_pair{|k,v| self[k.to_sym] = v }
    elsif constructor.respond_to?(:each_slice)
      constructor.each_slice(2){|k,v| self[k.to_sym] = v }
    elsif constructor != nil
      raise ArgumentError, "cannot initialize flexhash with #{constructor}", caller(3)
    end
  end

  def initialize_copy(orig)
    super
    @table = @table.dup
    @table.each_key { |key| new_flexhash_member(key) }
  end

  def to_h
    @table.dup
  end

  def each_pair
    return to_enum __method__ unless block_given?
    @table.each_pair { |p| yield p }
  end

  def marshal_dump
    @table
  end

  def marshal_load(x)
    @table = x
    @table.each_key{|key| new_flexhash_member(key)}
  end

  def modifiable
    begin
      @modifiable = true
    rescue
      raise TypeError, "can't modify frozen #{self.class}", caller(3)
    end
    @table
  end
  protected :modifiable

  def new_flexhash_member(name)
    name = name.to_sym
    unless respond_to?(name)
      define_singleton_method(name) { @table[name] }
      define_singleton_method("#{name}=") { |x| modifiable[name] = x }
    end
    name
  end
  protected :new_flexhash_member

  def method_missing(mid, *args, &block)
    mname = mid.id2name
    len = args.length
    if mname.chomp!('=')
      if len != 1
        raise ArgumentError, "wrong number of arguments (#{len} for 1)", caller(1)
      end
      modifiable[new_flexhash_member(mname)] = args[0]
    elsif len == 0
      @table[mid] || @table.send(mid, *args, &block)
    else
      @table.send(mid, *args, &block)
    end
  end

  def [](name)
    if Integer === name
      @table[name] || @table[@table.keys[name]]
    else
      res = @table[name] || @table[name.try(:to_sym)]
      return res if res
      res = @table.select{|k,v| name === k}
      return res.values[0] if res.size == 1
      res
    end
  end

  def []=(name, value)
    modifiable[new_flexhash_member(name)] = value
  end

  def <<(kv)
    name, value = kv
    self[name] = value
  end

  def delete_field(name)
    sym = name.to_sym
    singleton_class.__send__(:remove_method, sym, "#{name}=")
    @table.delete sym
  end

  InspectKey = :__inspect_key__ # :nodoc:

  def inspect
    str = "#<#{self.class}"

    ids = (Thread.current[InspectKey] ||= [])
    if ids.include?(object_id)
      return str << ' ...>'
    end

    ids << object_id
    begin
      first = true
      for k,v in @table
        str << "," unless first
        first = false
        str << " #{k}=#{v.inspect}"
      end
      return str << '>'
    ensure
      ids.pop
    end
  end
  alias :to_s :inspect

  attr_reader :table # :nodoc:
  protected :table

  def ==(other)
    return false unless other.kind_of?(OpenStruct)
    @table == other.table
  end

  def eql?(other)
    return false unless other.kind_of?(OpenStruct)
    @table.eql?(other.table)
  end

  def hash
    @table.hash
  end
end

# Kind of like FlexHash, but assumes the elements of the array have a :name method, and allows duplicates
class FlexArray < Array
  def [](position_or_name)
    return super if Fixnum === position_or_name
    res = self.find_all{|stream_port| position_or_name === stream_port.name}
    res = res[0] if res.size == 1
    res
  end

  def method_missing(mid, *args, &block)
    mname = mid.id2name
    len = args.length
    return self[mid] if len == 0
    super
  end
end
