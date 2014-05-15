require 'helper'
require 'nodus/statemachine'
include Nodus
# class MyStateMachine
#   include StateMachine
#   state :one, :two
#   states :three
#   state_methods :four
#   def one()    print '(1)'; :two    end
#   def two()    print '(2)'; :three  end
#   def three()  print '(3)'; :four   end
#   def four()   print '(4)'; :seven  end
#   def five()   5 end
#   state_method :four
# 
#   def six() 6 end
# 
#   state :this_does_not_exist
#   def state_seven()   print '(7)'; :done  end
# end

def remove_class(klass)
  const = klass.to_s.to_sym
  Object.send(:remove_const, const) if Object.send(:const_defined?, const)
end

describe StateMachine do
  after do
    remove_class :Subject
    remove_class :Subject2
  end

  it 'does not interfere with normal operations' do
    class Subject
      include StateMachine
      def initialize(a)  @a = a end
      def state_not_really() @a end
      def four()  print '(4)'   end
    end

    s = Subject.new(1)
    s.state_not_really.must_equal 1
    ->{ s.four }.must_output '(4)'
  end

  it 'allows methods to be declared as state methods' do
    class Subject
      include StateMachine
      state :one
      states :two, :three
      state_method :four
      state_methods :five, :six, :seven
      def one()   print '(1)' end
      def two()   print '(2)' end
      def three() print '(3)' end
      def four()  print '(4)' end
      def five()  print '(5)' end
      def six()   print '(6)' end
      def seven() print '(7)' end
      def not_a_state() :pass end
    end

    s = Subject.new
    s.not_a_state.must_equal :pass
  end

  it 'does not allow state methods to be called normally' do
    class Subject
      include StateMachine
      state :one
      states :two, :three
      state_method :four
      state_methods :five, :six, :seven
      def one()   print '(1)' end
      def two()   print '(2)' end
      def three() print '(3)' end
      def four()  print '(4)' end
      def five()  print '(5)' end
      def six()   print '(6)' end
      def seven() print '(7)' end
    end

    s = Subject.new
    [:one, :two, :three, :four, :five, :six, :seven].each do |num_word|
      ->{ s.send num_word }.must_raise RuntimeError
    end
  end

  it 'propagates through the state machine until done' do
    class Subject
      include StateMachine
      states :one, :two, :three, :four
      def one()   print '(1)'; :two   end
      def two()   print '(2)'; :three end
      def three() print '(3)'; :four  end
      def four()  print '(4)'; :done  end
    end

    ->{ Subject.new.start_statemachine(:one) }.must_output '(1)(2)(3)(4)'
  end

  it 'raises errors when state implementations are missing' do
    class Subject
      include StateMachine
      states :one, :two, :three, :four
      def one()  :two   end
      def two()  :three end

      def four() :done  end
    end

    ->{ Subject.new.start_statemachine(:one) }.must_raise NoMethodError
  end

  it 'defaults the first state to :initial' do
    class Subject
      include StateMachine
      states :initial
      def initial()  print '(i)'; :done end
    end

    ->{ Subject.new.start_statemachine }.must_output '(i)'

    class Subject2
      include StateMachine
      states :initial
      def one()  print '(1)'; :done end
    end

    ->{ Subject2.new.start_statemachine }.must_raise NoMethodError
  end
end
