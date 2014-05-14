module Nodus
  module StateMachine
    def self.included(s)
      s.instance_methods(false).each do |m|
        next unless m =~ /^state_/
        # TODO: Allow dropping 'state_' in next_state return value
        s.class_eval %Q{private :#{m.to_sym}}
      end
    end
  end

  class TestMachine
    def test(a)
      puts 'hi'
    end

    # TODO: YOU ARE HERE. move this into statemachine and expand as appropriate
    def run
      @current_state = :state_initial
      loop do
        @current_state = self.send(@current_state)
        raise ArgumentError, "Didn't return a valid state." unless self.respond_to?(@current_state.to_s, true)
      end
    end

    def state_initial
      puts 'in the state'
      :state_next
    end


    def state_next

      :state_initial
    end

    include StateMachine
  end
end
