
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
  def_exception :AmbiguousBinding, "Ambiguous binding; select a more specific stream/branch port: %s", ArgumentError

  class BranchPort
    attr_reader :name
    def initialize(parent_stream_port, name)
      @stream_port, @name = parent_stream_port, name
    end

    def full_name()     "#{@stream_port.try(:full_name)}.#{name}"   end
    def unbound?()       true end
    def inspect()       "<#{full_name}>" end
  end

  class InputBranchPort < BranchPort
    def next_input() self           end
    def unbound?()   @source.blank? end
    def listen_to(output_port)
      output_branchport = output_port.next_output
      return [self,@source] if @source == output_branchport
      raise RuntimeError, "This input port is already bound to #{@source.full_name}. (attempting #{output_branchport.full_name})" if @source
      @source = output_branchport
      output_branchport.add_subscriber(self)
    end
  end

  class OutputBranchPort < BranchPort
    def next_output() self                end
    def unbound?()    subscribers.blank?  end
    def subscribers() @subscribers ||= [] end
    def add_subscriber(input_port)
      input_branchport = input_port.next_input
      return [input_branchport, self] if subscribers.include?(input_branchport)
      subscribers << input_branchport
      input_branchport.listen_to(self)
    end
  end

  class StreamPort
    attr_reader :name, :branches
    def initialize(parent_node, name, branches=[:main])
      @parent, @name = parent_node, name
      @branches = FlexHash[branches.try(:map){|b| [b, build_branch(b)]}]
    end

    def kind()             :undefined end
    def build_branch(name) BranchPort.new(self, name) end
    def full_name()       "#{@parent.try(:name)}.#{kind}.#{name}" end
    def inspect()         "<#{full_name}>" end

    def method_missing(m,*args,&block)
      return @branches.send(m, *args, &block) if @branches.respond_to?(m)
      super
    end
  end

  class InputStreamPort < StreamPort
    def kind()                :inputs                           end
    def build_branch(name)    InputBranchPort.new(self, name)   end
    def listen_to(other_port) next_input.listen_to(other_port)  end
    def next_input()          (branches.find{|nm,br| br.unbound?}.try(:[],1) || branches[0]).next_input end
  end

  class OutputStreamPort < StreamPort
    def kind()                :outputs end
    def build_branch(name)    OutputBranchPort.new(self, name)  end
    def add_subscriber(sub)   next_output.add_subscriber(sub) end

    # Default to first branch if none seem available.
    # It's the branch's job to actually allow a binding to occur or not etc.
    #
    # This is perhaps too much logic. It might be better to assume ":main" branch if no branch specifier is given,
    # instead of checking all the branches.
    def next_output() (branches.find{|nm,br| br.unbound?}.try(:[],1) || branches[0]).next_output end
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
    protected def input (*names) inputs.concat (names.flat_map{|n|  InputStreamPort.new(self,n)}) end
    protected def output(*names) outputs.concat(names.flat_map{|n| OutputStreamPort.new(self,n)}) end

    # Instance inputs/outputs (initialized with a copy of the class-defined ones)
    def inputs () @inputs  ||= FlexArray.new(self.class.c_inputs .map{|n|  InputStreamPort.new(self, n)}) end
    def outputs() @outputs ||= FlexArray.new(self.class.c_outputs.map{|n| OutputStreamPort.new(self, n)}) end

    def initialize(name=nil)
      @name = name || self.class.name
    end

    def next_input
      error(AmbiguousBinding, inputs) if inputs.size > 1
      inputs[0].next_input
    end

    def next_output
      error(AmbiguousBinding, outputs) if outputs.size > 1
      outputs[0].next_output
    end

    def listen_to     (other_port) next_input.listen_to      (other_port) end
    def add_subscriber(other_port) next_output.add_subscriber(other_port) end
  end
end
