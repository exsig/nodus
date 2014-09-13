module Nodus::Atoms
  class Base
    attr_reader :parameters, :streams

    def initialize
      @parameters = {}
      @streams    = {}
      streams[:primary] = Stream.new
      yield self if block_given?
    end
  end

  class Parameter
    attr_accessor :name, :datatype, :default, :required
    def initialize(name, datatype, default=:__none__, required=true)
      @name       = name
      @datatype   = datatype
      @default    = default
      @required   = required
    end
  end

  class Stream
    attr_accessor :name
    attr_reader   :in_ports, :out_ports
    def initialize(name, in_ports=[], out_ports=[])
      @name       = name
      @in_ports   = in_ports
      @out_ports  = out_ports
    end
  end

  class Port
    attr_accessor :name, :datatype
    def initialize(name, datatype)
      @name = name
      @datatype = datatype
    end
  end
end
