
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
    attr_reader :name
    def initialize(parent_stream_port, name)
      @stream_port, @name = parent_stream_port, name
    end

    def full_name()     "#{@stream_port.try(:full_name)}:#{name}"   end
    def next_bindable() self end
    def unbound?()      @source.blank? && subscribers.blank?  end
    def subscribers()   @subscribers ||= []              end

    def listen_to(output_port)
      output_branchport = output_port.next_bindable
      return [self,@source] if @source == output_branchport
      raise ArgumentError, "This input port is already bound to #{@source.full_name}. (attempting #{output_branchport.full_name})" if @source
      @source = output_branchport
      output_branchport.add_subscriber(self)
    end

    def add_subscriber(input_port)
      input_branchport = input_port.next_bindable
      return [input_branchport, self] if subscribers.include?(input_branchport)
      subscribers << input_branchport
      input_branchport.listen_to(self)
    end

    def inspect
      "#<#{full_name}>"
    end
  end

  class StreamPort
    attr_reader :name, :branches
    def initialize(parent_node, name, branches=[:main])
      @parent, @name = parent_node, name
      @branches = FlexHash[branches.try(:map){|b| [b, BranchPort.new(self, b)]}]
    end

    def method_missing(m,*args,&block)
      return @branches.send(m, *args, &block) if @branches.respond_to?(m)
      super
    end

    def full_name()     "#{@parent.try(:name)}:#{name}" end
    def next_bindable() branches.select{|name, branch| branch.unbound?}[0] end
  end

  class InputPort < StreamPort
    def listen_to(other_port)
      raise RuntimeError, "All branches for port #{name} are already bound." unless next_bindable
      next_bindable.listen_to(other_port)
    end
  end

  class OutputPort < StreamPort
    def add_subscriber(peer_input_port)
      next_bindable.add_subscriber(peer_input_port)
    end

    def next_bindable()
      candidate   = super
      candidate ||= branches[0] # default to more listeners on only first branch if all are listened to
    end
  end

  class Node
    attr_reader :name

    class << self
      def [](*args) new(*args) end

      # Hold stream inputs/outputs defined at the class level
      def c_inputs () @c_inputs  ||= [] end
      def c_outputs() @c_outputs ||= [] end

      # Define class-level inputs/outputs
      protected def input    (*names) c_inputs.concat (names.flatten) end
      protected def output   (*names) c_outputs.concat(names.flatten) end
    end

    # For defining instance-level inputs/outputs
    protected def input (*names) inputs.concat (names.flat_map{|n|  InputPort.new(self,n)}) end
    protected def output(*names) outputs.concat(names.flat_map{|n| OutputPort.new(self,n)}) end

    # Instance inputs/outputs (initialized with a copy of the class-defined ones)
    def inputs () @inputs  ||= FlexArray.new(self.class.c_inputs .map{|n|  InputPort.new(self, n)}) end
    def outputs() @outputs ||= FlexArray.new(self.class.c_outputs.map{|n| OutputPort.new(self, n)}) end

    def initialize(name=nil)
      @name = name || self.class.name
    end
  end
end
