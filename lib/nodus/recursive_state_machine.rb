# Different from the usual Ruby statemachine implementations where methods are more or less events and states and
# transitions are declaratively defined. In this implementation you simply start_statemachine() and the initial state
# method is invoked. It does its thing and possibly blocks or yields, and eventually returns a symbol for the next state
# to transition to. In other words- the natural way state machines are implemented in more functional languages,
# modified slightly because Ruby generally lacks tail-call elimination.
#
require 'nodus'

module Nodus
  module RecursiveStateMachine
    def self.included(k) k.extend ClassMethods end

    def start_statemachine(initial_state = nil)
      @current_state = initial_state || @initial_state || :initial
      loop do
        @current_state = self.send("__#{@current_state}")
        break if @current_state == :done
      end
    end

    module ClassMethods
      # Simply overrides the method(s) with an error if called directly, and sets up one (or possibly two- a second
      # without 'state_' prepended) methods with leading underscores that the statemachine runtime loop calls as
      # appropriate for original functionality.
      #
      # It's implemented here by prepending anonymous modules. This is so that everything can be set up within the class
      # even if the module is included and state_method(...)'s are declared before any of the methods are actually
      # defined. See for example: http://gshutler.com/2013/04/ruby-2-module-prepend/
      #
      def state(*method_names)
        method_names.each do |mname|
          anon_module = Module.new do
            define_method mname do super end # Sets up method with original functionality even if it's not defined yet in the including class
            alias_method "__#{mname}", mname
            alias_method("__#{mname[6..-1]}", mname) if mname =~ /^state_/
            define_method mname do
              raise RuntimeError, "Sorry, this is a state method now. If you really, really need to call it like a normal function, send :__#{mname}"
            end
            private "__#{mname}"
            private "__#{mname[6..-1]}" if mname =~ /^state_/
          end
          prepend anon_module
        end
      end
      alias_method :states,        :state
      alias_method :state_method,  :state
      alias_method :state_methods, :state
    end
  end
end

