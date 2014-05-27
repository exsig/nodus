require 'ostruct'
require 'thread'

# TODO: Always automatically an output 'port' that is for exceptions & signals. Possibly specify restart strategy
# instead of relying on a supervisor?

module Nodus
  class NodeError < ThreadError; end
  def_exception :OutputWriteError, "Node only accepts data on input ports",  IOError
  def_exception :OutputReadError,  "Node should only read from input ports", IOError
  def_exception :InputReadError,   "Node only gives data via output ports",  IOError
  def_exception :InputWriteError,  "Node should only write to output ports", IOError

  class NodePort
    attr_accessor :name, :kind, :desc, :node_type, :channel, :bound_peer
    MAX_BACKLOG = 1024 # Number of queued objects before adding more objects blocks
    def initialize(name, kind=Integer, desc=nil)
      @node_type  = nil
      @name       = name.to_s.to_sym
      @kind       = kind
      @desc       = desc
      @channel    = Rubinius::Channel.new
      @sem        = Mutex.new
      @bound_peer = nil
      @backlog    = 0
    end

    def bound?()
      @bound_peer.present?
    end

    def bind(peer, binder)
      return peer if bound? && @bound_peer == peer
      error RuntimeError, "Cannot rebind port" if bound?
      @bound_peer = peer
      @binder     = binder
    end

    def this() Thread.current end

    def attach(master_node)
      @master_node = master_node
      @master_node_thread = master_node.thread
    end

    def inside_master?
      alive? && @master_node_thread == this
    end

    def alive?
      @channel && @master_node && @master_node_thread && @master_node_thread.alive?
    end

    def send(val)
      if @backlog > MAX_BACKLOG
        pri = this.priority
        this.priority = -4
        Thread.pass while @backlog > MAX_BACKLOG # Not synchronizing because being off by a few isn't a big deal
        this.priority = pri # might not work... might permanently be set at lower...
      end
      @channel << val
      @backlog += 1
      self # self on the end so it's chainable
    end

    def receive()
      res = @channel.receive
      @backlog -= 1
      res
    end

    def detach
      @channel = @master_node = @master_node_thread = nil
    end
  end

  # InputNodePort and OutputNodePort currently just ensure that the data flows the correct direction- that is, input
  # ports can only be written to from outside the node and only be read from inside the node, and visa versa for output
  # ports. i.e.:
  #
  #                |   input  |   output
  # ---------------|----------|-----------
  # outside-world  |   <<     |  receive
  # within node    | receive  |    <<
  #
  class InputNodePort < NodePort
    attr_accessor :feed_peer
    def initialize(*) super; @node_type = :input end
    def send(*)    error InputWriteError     if inside_master? ; super end
    def receive(*) error InputReadError  unless inside_master? ; super end
    alias_method :<<, :send
  end

  class OutputNodePort < NodePort
    def initialize(*) super; @node_type = :output end
    def send(*)    error OutputWriteError unless inside_master? ; super end
    def receive(*) error OutputReadError      if inside_master? ; super end
    alias_method :<<, :send
    def |(input_to_bind)
      raise ArgumentError, "Output ports can only be bound to input ports." unless InputNodePort === input_to_bind
      raise RuntimeError,  "Output port already bound" if bound?
      raise RuntimeError,  "Input port already bound"  if input_to_bind.bound?
      PortBinding[self, input_to_bind]
    end
    # TODO: ensure that, once bound, only the binder can receive.
    # TODO: alternatively- on first receive and first send record the thread id or some other UID and only allow that
    # one to send/receive from then on.
  end

  class PortBinding
    attr_reader :thread
    delegate :status, to: :thread

    def self.[](from_port, to_port) self.new(from_port, to_port) end

    def initialize(from_port, to_port)
      raise ArgumentError, 'from-port must be an output port of a node' unless OutputNodePort === from_port
      raise ArgumentError, 'to-port must be an input port of a node'    unless InputNodePort  === to_port
      from_port.bind  to_port,   self
      to_port.bind    from_port, self

      from_port = WeakRef.new(from_port)
      to_port   = WeakRef.new(to_port)
      @thread = Thread.new do
        loop do
          break unless from_port && to_port
          val = from_port.receive
          break unless from_port && to_port
          to_port << val
        end
      end
    end
  end


  def_exception :DuplicatePortError,    "Ports were specified on the node with duplicate port names (%s)", ArgumentError
  def_exception :RestartError,          "Can't restart node- it's still alive",                            NodeError
  def_exception :DeadNodeError,         "Can't find a port for a dead node (%s)",                          NodeError
  def_exception :UnresponsiveNodeError, "Can't find a port for an unresponsive node (won't join)",         NodeError

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
      error RestartError if alive?
      detach_ports()
      @active = true
      starting = Rubinius::Channel.new # Used to make sure this method doesn't return until ports are attached in the other thread
      @thread = Thread.new do
        @thread = Thread.current
        attach_ports()
        starting << true
        start_statemachine(:start) # <-- this will loop until an exception or one of the states returns :done

        @active = false
        detach_ports()
        :normal_exit
      end
      starting.receive
    end

    def alive?
      @active && @thread.alive?
    end

    def parameterize() :redefine_me end

    # TODO: Fix. This isn't actually doing anything due to state-machine being prepended... NoMethodError is happening instead
    def start
      raise NotImplementedError, "You must define an 'start' state method."
    end

    def multi_receive(ports)
      # TODO basically set up a separate thread waiting on each port which then resume the main thread when something
      # arrives (and killing the other[s]). difficulty will be ensuring no lost messages on the other channel(s). This
      # may also be implemented as a different kind of merged port pseudo-port...
      raise NotImplementedError
    end

    def input_ports()  @active_inputs  ||= {} end
    def output_ports() @active_outputs ||= {} end

    private

    def methodize_ports
      metaclass = class << self; self; end
      [[inputs, :@active_inputs], [outputs, :@active_outputs]].each do |ports, active_list|
        ports.each do |p|
          metaclass.send(:define_method, p.name) do
            if alive? then instance_variable_get(active_list)[p.name]
            else
              # The join here is largely to elicit an internal exception as appropriate
              @thread.join(0.1) ? error(DeadNodeError, @thread.value) : error(UnresponsiveNodeError)
            end
          end
        end
      end
    end

    def validate_ports
      # TODO: make sure at least one port total
      all_ports = self.inputs + self.outputs
      port_names = all_ports.map{|p| p.name}
      port_names.sort.reduce(nil) do |last, curr|
        error DuplicatePortError, last if last == curr
        curr
      end
    end

    def detach_ports
      (input_ports.values + output_ports.values).each{|p| p.detach}
      @active_inputs  = {}
      @active_outputs = {}
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
