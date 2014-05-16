require 'ostruct'

module Nodus
  class NodePort
    attr_accessor :name, :kind, :desc, :node_type
    def initialize(name, kind=Integer, desc=nil)
      @node_type = nil
      @name      = name.to_s.to_sym
      @kind      = kind
      @desc      = desc
      @channel   = Rubinius::Channel.new
    end

    def attach(master_node)
      @master = master_node
      @master_thread = master_node.thread
    end

    def inside_master?
      @master && @master_thread && @master_thread.alive? && @master_thread == Thread.current
    end

    def send(val) @channel << val; self end # self on the end so it's chainable
    def receive() @channel.receive end
  end


  #                |   input  |   output
  # ---------------|----------|-----------
  # outside-world  |   <<     |  receive
  # within node    | receive  |    <<
  #
  class InputNodePort < NodePort
    def initialize(*)
      super
      @node_type = :input
    end

    def send(token)
      raise RuntimeError, "Can't send to an input port from inside the node." if inside_master?
      super
    end
    alias_method :<<, :send

    def receive()
      raise RuntimeError, "Can't receive from an input port- try from an output port." unless inside_master?
      super
    end
  end

  class OutputNodePort < NodePort
    def initialize(*)
      super
      @node_type = :output
    end

    def send(token)
      raise RuntimeError, "Can't send to an output port- try an input port." unless inside_master?
      super
    end
    alias_method :<<, :send

    def receive()
      raise RuntimeError, "Can't receive from an output port from inside the node." if inside_master?
      super
    end
  end

  class Node
    include Nodus::StateMachine

    attr_reader :inputs, :outputs, :thread

    delegate :join, :value, :status, to: :thread

    def self.pass() Thread.pass end
    def pass() Thread.pass end

    def self.c_inputs () @c_inputs  ||= [] end
    def self.c_outputs() @c_outputs ||= [] end
    def self.input (sym, kind=Integer, desc=nil) c_inputs  << OpenStruct.new(name: sym, kind: kind, desc: desc) end
    def self.output(sym, kind=Integer, desc=nil) c_outputs << OpenStruct.new(name: sym, kind: kind, desc: desc) end
    def      input (sym, kind=Integer, desc=nil) @inputs   << OpenStruct.new(name: sym, kind: kind, desc: desc) end
    def      output(sym, kind=Integer, desc=nil) @outputs  << OpenStruct.new(name: sym, kind: kind, desc: desc) end

    def initialize(*args, &block)
      @inputs  = [] + self.class.c_inputs
      @outputs = [] + self.class.c_outputs
      parameterize(*args, &block)
      validate_ports()
      methodize_ports()
      restart()
    end

    def restart
      raise RuntimeError, "Can't restart- it's still alive." if alive?
      @active_inputs  = {}
      @active_outputs = {}
      @active = true
      starting = Rubinius::Channel.new
      @thread = Thread.new do
        @thread = Thread.current
        attach_ports()
        starting << true
        start_statemachine(:start)
        @active = false
        @active_inputs  = {}
        @active_outputs = {}
        :normal_exit
      end
      starting.receive
    end

    def alive?
      @active && @thread.alive?
    end

    def parameterize() :redefine_me end

    def start
      raise RuntimeError, "You must define an 'start' method which is the first state for the node."
    end

    private

    def methodize_ports
      metaclass = class << self; self; end
      [[inputs, :@active_inputs], [outputs, :@active_outputs]].each do |ports, active_list|
        ports.each do |p|
          metaclass.send(:define_method, p.name) do
            if alive? then instance_variable_get(active_list)[p.name]
            else raise RuntimeError, "Can't find a port for a dead node." end
          end
        end
      end
    end

    def validate_ports
      # TODO: make sure at least one port total
      all_ports = self.inputs + self.outputs
      port_names = all_ports.map{|p| p.name}
      port_names.sort.reduce(nil) do |last, curr|
        raise RuntimeError, "Ports were specified on node with duplicate port names: #{last}" if last == curr
        curr
      end
    end

    def attach_ports
      inputs.each do |p|
        @active_inputs[p.name] = InputNodePort.new(p.name, p.kind, p.desc)
        @active_inputs[p.name].attach(self)
      end

      outputs.each do |p|
        @active_outputs[p.name] = OutputNodePort.new(p.name, p.kind, p.desc)
        @active_outputs[p.name].attach(self)
      end
    end
  end
end










# in-ports
# out-ports
# enumable
# actorable
# generator

#  module Node
#    # Goals
#    #   - classes can act in a simple manner or essentially as actors- so for example, FDiff uses the Lag as well as
#    #     sub-classed FDiffs. It may need to be its own actor but Lag and its subclasses shouldn't have to be their own
#    #     threads. In another case though, Lag may need to be on its own thread.
#    # Notes
#    #   - Lazy enum more appropriate for the "core" nodes?
#    #   - Ruby stream mechanisms?
#    class Lag
#      def initialize(size) @buff = Array.new(size, nil) end
#      def next(x) (@buff << x).shift end
#    end
#
#    class FDiff
#      def initialize(lag=1, cap=4)
#        @lag = Lag.new(lag)
#        @cap = cap
#        @next_order = FDiff.new(1, @cap - 1) if @cap > 1
#      end
#
#      def next(x)
#        prev = @lag.next(x)
#        diff = (prev.nil? || x.nil?) ? nil : x - prev
#        res  = [diff]
#        res += @next_order.next(diff) if @cap > 1
#        res
#      end
#    end
#  end


# module Nodus
#   module Random
#     class Uniform
#       include Enumerable
# 
#       def initialize(range=nil, seed=nil)
#         @seed  = seed || ::Random.new_seed
#         @range = range || 1.0
#         @prng  = ::Random.new(@seed)
#       end
# 
#       def each
#         loop do
#           yield @prng.rand(@range)
#         end
#       end
#     end
#   end
# end

#  * Implied indexing/context object
#  * 


#module Nodus
#  class RandomUniform < Nodus::Node
#    out_port      :y
#    initial_state :main
#    def parameterize(range=1.0, seed=nil)
#      @seed  = seed  || ::Random.new_seed
#      @range = range || 1.0
#      @prng  = ::Random.new(@seed)
#    end
#
#    def main
#      y.emit @prng.rand(@range)
#    end
#  end
#end


#  src = Nodus::RandomUniform.new
#  
#  
#  sources = [:oanda, :truefx].map{|data_source| 
#  
#  [:oanda, :truefx].map do |source_name|
#    Nodus::Accumulator.new do |acc|
#      acc.source = Nodus::FXSource[source_name]
#      acc.
