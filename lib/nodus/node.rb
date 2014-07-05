
# Phases
# 1. Kernel-design time:
#    - designate input/output ports/streams
# 2. Design-time:
#    - specify bindings as much as possible
#    - compose
#    - pre-initialize/parameterize as appropriate
#    - specify process network / highest level compositions
# 3. Pre-runtime:
#    - static compliance-check
#    - display process network graph
#    - warnings / errors as appropriate
# 4. Runtime:
#    - dynamic parameterization as appropriate
#    - dynamic running nodes as appropriate
#    - contexts and real stream instances
#

# Specialized (out of band) input/output ports
#   - new output available
#   - new input available (?)
#   - output subscribed by...
#   - input bound by...
#   (allows nodes to communicate in an out-of-band fassion... easier to simply specify the peer object in initialize and
#   make sure every node has a general out-of-band communication channel where senders say who they are?)
#
# * Inputs can be bound to only one output
# * Outputs can be subscribed to by any number of other nodes
# * Binding to a node itself assumes the correct input/output if only one of either is available
#


module Nodus
  class BranchPort
    def initialize(parent_stream, name)
      @stream, @name = parent_stream, name
    end
  end

  class StreamPort
    attr_reader :name
    def initialize(name, branches=[:main])
      @name = name
      @branches = FlexHash[branches.try(:map){|b| [b, BranchPort.new(self, b)]}]
    end

    def method_missing(m,*args,&block)
      return @branches.send(m, *args, &block) if @branches.respond_to?(m)
      super
    end
  end

  class Node
    def self.input    (*names) c_inputs .concat(names.flat_map{|n| StreamPort.new(n)}) end
    def self.output   (*names) c_outputs.concat(names.flat_map{|n| StreamPort.new(n)}) end
    def      input    (*names) inputs   .concat(names.flat_map{|n| StreamPort.new(n)}) end
    def      output   (*names) outputs  .concat(names.flat_map{|n| StreamPort.new(n)}) end

    def self.c_inputs () @c_inputs  ||= FlexArray.new end
    def self.c_outputs() @c_outputs ||= FlexArray.new end
    def      inputs   () @inputs    ||= Marshal.load(Marshal.dump(self.class.c_inputs))  end
    def      outputs  () @outputs   ||= Marshal.load(Marshal.dump(self.class.c_outputs)) end

    def self.[](*args) new(*args) end



  end
end
