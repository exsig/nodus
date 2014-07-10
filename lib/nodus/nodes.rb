class Object
  def kind_of_node?() false end
end

module Nodus
  module Nodes
    class Param < PropSet
      default required: false,  hidden:    false
      inverse visible: :hidden, required: :optional
      def realize(val) self.default = val; self.hidden = true end
      def realized?()  self.hidden? || self.optional? || self.has_default? end
      def realized()
        return self.default if self.has_default?
        error RuntimeError, "Parameter #{self.name} is required but hasn't had any values set." if self.required?
        nil
      end
    end

    #class StreamPort < PropSet
    #  inverse input: :output
    #end

    class Node
      class << self
        def kind_of_node?()    true end

        def parameters()       @parameters ||= PropList.new(Param) end
        def parameters=(p)     @parameters   = p                   end
        def param(name, *args) parameters   << [name, args]        end

        def inherited(subclass)
          subclass.parameters = parameters.dup
        end

        attr_accessor :name

        def compose(*args, &block)
          Class.new(self) do |new_klass|
            on_compose(*args)
            new_klass.instance_exec(new_klass, &block) if block_given?
          end
        end

        # Override this at will with whatever parameters you want- just remember to call super, and with the right
        # parameters
        def on_compose(name)
          error ArgumentError, "First argument to compose needs to be the symbolic name, not `#{name.inspect}`" unless name.kind_of? Symbol
          self.name = name
        end

        # TODO:
        # undefined_parameters()  #=> tell what required parameters don't have defaults set
        # complete?() #=> all required parameters & connections defined (well enough)
      end


      # --------------------------------- Instance --------------------------------------------------------

      def parameters() @parameters ||= self.class.parameters.dup end
      # Initialize will usually allow any parameters (/parameter overrides), and any object-level connection information
      # required.
      def initialize(*params)
        # fill params with non-hash heads of args and then use any remaining hash to fill in more params
        # runtime error if some required parameters are not set
      end
    end


    class ConcurrentNode < Node
      class << self
        # Defined by aggregate of all parameters, input ports, and output ports (of all kinds). Probably automatically
        # need their own naming conventions...

        def on_compose(name, *inner_nodes)
          super(name)
          inner_nodes.each do |node|
            STDERR.puts "Composed from: #{node.name}"
          end
        end
      end
    end


    class Pipe < Node

    end
  end
end




        # CLASS LEVEL CURRYING
        # def new_parameterized_class(newname, param_defs={})
        #   current_parameters = parameters
        #   klass = Class.new(self) do |mod|
        #     # Merge/append with new parameters
        #     param_defs.each{|name, opts| mod.param(name, opts)}
        #   end
        #   Object.const_set(newname, klass)
        # end


  # class Node
  #   attr_reader :name

  #   class << self
  #     def [](*args) new(*args) end

  #     # Hold stream inputs/outputs defined at the class level
  #     def c_inputs () @c_inputs  ||= [] end
  #     def c_outputs() @c_outputs ||= [] end

  #     # Define class-level inputs/outputs
  #     protected def input    (*names) c_inputs.concat (names.flatten) end
  #     protected def output   (*names) c_outputs.concat(names.flatten) end
  #   end

  #   # For defining instance-level inputs/outputs
  #   protected def input (*names) inputs.concat (names.flat_map{|n|  InputStreamPort.new(self,n)}) end
  #   protected def output(*names) outputs.concat(names.flat_map{|n| OutputStreamPort.new(self,n)}) end

  #   # Instance inputs/outputs (initialized with a copy of the class-defined ones)
  #   def inputs () @inputs  ||= FlexArray.new(self.class.c_inputs .map{|n|  InputStreamPort.new(self, n)}) end
  #   def outputs() @outputs ||= FlexArray.new(self.class.c_outputs.map{|n| OutputStreamPort.new(self, n)}) end

  #   def initialize(name=nil)
  #     @name = name || self.class.name
  #   end

  #   def next_input
  #     error(AmbiguousBinding, inputs) if inputs.size > 1
  #     inputs[0].next_input
  #   end

  #   def next_output
  #     error(AmbiguousBinding, outputs) if outputs.size > 1
  #     outputs[0].next_output
  #   end

  #   def listen_to     (other_port) next_input.listen_to      (other_port) end
  #   def add_subscriber(other_port) next_output.add_subscriber(other_port) end
  # end
