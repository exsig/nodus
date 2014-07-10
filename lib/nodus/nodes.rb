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
      class_attr_inheritable :parameters, PropList.new(Param)
      class_attr_inheritable :title,      nil
      class_attr_inheritable :sub,        []  # Sub-nodes- mostly for later subclasses

      class << self
        def kind_of_node?()    true end
        def param(param_name, *args) parameters << [param_name, args]  end

        def compose(*args, &block)
          Class.new(self) do |new_klass|
            new_klass.on_compose(*args)
            new_klass.instance_exec(new_klass, &block) if block_given?
          end
        end
        alias_method :[], :compose

        # Override this at will with whatever parameters you want- just remember to call super, and with the right
        # parameters
        def on_compose(title)
          error ArgumentError, "First argument to compose needs to be the symbolic title, not `#{title.inspect}`" unless title.kind_of? Symbol
          self.title = title
        end

        # TODO:
        # undefined_parameters()  #=> tell what required parameters don't have defaults set
        # complete?() #=> all required parameters & connections defined (well enough)
      end


      # --------------------------------- Instance --------------------------------------------------------

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

        def on_compose(title, *inner_nodes)
          super(title)
          inner_nodes.each do |node|
            STDERR.puts "Composed from: #{node.title}"
          end
        end
      end
    end


    class Pipe < Node

    end

    # Given: enumerator or something that can be to_enum'ed
    # Given: lambda or proc or block - params are gathered by reflection
    # Given: class - assumed to be enumerable (or perhaps have a wrappable loop function?) params gathered via
    #        reflection on initialize.
    # see http://stackoverflow.com/questions/4982630/trouble-yielding-inside-a-block-lambda when we get to lambdas etc.
    #
    class Generator < Node
      class << self
        def on_compose(title, kernel=nil, &block)
          super(title)
          @kernel = kernel || block
          @kernel = case @kernel
                    when Enumerator then @kernel.lazy # No parameters
                    when Class
                      init_params = @kernel.instance_method(:initialize).parameters
                      init_params.each{|kind,pname| param(pname, (kind == :req ? :required : :optional))}
                    when Node
                      # TODO: Simply verify that the kernel has no input ports and create this thin wrapper around it...
                      # Although it still might make sense to warn that this is a senseless act? (unless it becomes
                      # necessary for some sorts of renaming etc.?)
                      error NotImplementedError
                    else
                      error ArgumentError, "Generator Nodes don't support #{kernel.inspect} as a kernel"
                    end
        end
      end
    end
  end
end

# given:
#    parent_1   :   p1, p2, p3
#    parent_2   :       p2, p3, p4
#    parent_3   :                  p5
#
#
#    parent_1__p1 -> valid
#    parent_1__p2 -> valid
#    ...
#
#    p1, p4, p5         -> valid (maps to parent_1__p1 etc.)
#    p2, p3             -> exception asks parent_1__... or parent_2__...?
#    parent_1, parent_2 -> exception asks which property (p1, p2, or p3), or (p2, p3, p4)
#    parent_3           -> valid (maps to parent_3__p5)
#
#    doesn't solve the problem of nodes having the same name running in a concurrent composition (for example)!
#
#    ability to rename params & ports as they get composed... (or as something else done while currying etc...)
#




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
