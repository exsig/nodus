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

    class StreamPort < PropSet
      # `| input:  (operational<output-port[s]> | consumed  [control]) x (optional | required)`
      # `| output: ( operational<input-port[s]> | generated [control]) x (tap      |  primary)`

      inverse input:    :output
      inverse optional: :required
      inverse tap:      :primary
      inverse control:  :stream

      default optional: true
      default primary:  true
    end

    # I think we'll want the following to be completely disjoint:
    # (common methods) ⊔ (node methods) ⊔ (parameter names) ⊔ (node names) ⊔ (stream-port names)
    # This way we can do method_missing safely to specify params, nodes, ports, or anything else depending on the context.
    #
    # TODO: make nodes aware of their container? in order, perhaps, for them to ask the container who they should be
    # connected to instead of the other way around?
    #
    class Node
      class_attr_inheritable :title,           nil
      class_attr_inheritable :parameters,      PropList.new(Param)
      class_attr_inheritable :symmetric_ports, PropList.new(StreamPort)
      class_attr_inheritable :consumed_ports,  PropList.new(StreamPort)
      class_attr_inheritable :generated_ports, PropList.new(StreamPort)

      class_attr_inheritable :sub,             FlexArray.new  # Sub-nodes- mostly for later subclasses
      class_attr_inheritable :channels,        FlexArray.new  # Binding pairs of inner nodes

      class << self
        def kind_of_node?()    true end
        def param(param_name, *args)
          arg_hash = (Hash === args.last ? args.pop : {})
          arg_hash.merge!({name: param_name, node: self.title, node_type: self, node_name: self.name})
          parameters << [param_name, args << arg_hash]
        end

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

        def on_compose(title, *sub_nodes)
          super(title)
          sub_nodes.each{|node| sub << node}
        end

        #def parameters
        #  sub.map{|s| s.parameters}
        #end
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
        attr_reader :kernel

        def on_compose(title, kernel=nil, &block)
          super(title)
          @kernel = kernel || block
          case @kernel
          when Enumerator then @kernel = @kernel.lazy # No parameters
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
