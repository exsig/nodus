module Nodus
  module Node
    class Parameter
      attr :name, :default
      def initialize(name, opts={})
        @name = name.to_sym
        merge_opts(opts || {})
      end

      def merge_opts(opts={})
        @default  =  opts.delete(:default)  if opts.has_key?(:default)
        @required =  opts.delete(:required) if opts.has_key?(:required)
        @required = !opts.delete(:optional) if opts.has_key?(:optional)
        remove_instance_variable(:@default) if opts[:no_default]
      end

      def required?() @required || false                    end
      def optional?() !required?                            end
      def default?()  instance_variable_defined?(:@default) end
      def inspect()   "#<param #{name}#{required? ? '*' : ''}#{default? ? "=#{default}" : ''}>" end
    end

    class ParameterList < Delegator
      def initialize()  @data = {}; super(@data) end
      def __getobj__()  @data                    end
      def __setobj__(o) @data = o                end
      def dup() Marshal.load(Marshal.dump(self)) end
      def inspect()     @data.values.inspect     end

      def <<(param_init_args)
        if Array === param_init_args
          name, opts = param_init_args
          name = name.to_sym
          if   @data[name] then @data[name].merge_opts(opts || {})
          else @data[name] = Parameter.new(name, opts) end
        elsif Parameter === param_init_args
          if   @data[param_init_args.name] then raise ArgumentError, "Haven't yet implemented parameter merging"
          else @data[param_init_args.name] = param_init_args.dup end
        else raise ArgumentError, "Can't use #{param_init_args.inspect} for a new parameter" end
      end
    end

    class Base
      class << self
        def parameters()   @parameters ||= ParameterList.new end
        def parameters=(p) @parameters   = p                 end
        def param(*args)   parameters << args                end

        # CLASS LEVEL CURRYING
        def new_parameterized_class(newname, param_defs={})
          current_parameters = parameters
          klass = Class.new(self) do |mod|
            # Propagate parent parameters
            mod.parameters = current_parameters.dup

            # Merge/append with new parameters
            param_defs.each{|name, opts| mod.param(name, opts)}
          end
          Object.const_set(newname, klass)
        end
      end

      def initialize(*params)
        pp parameters
        # fill params with non-hash heads of args and then use any remaining hash to fill in more params
      end

      def parameters
        @parameters ||= self.class.parameters.dup
      end

    end
  end
end



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
