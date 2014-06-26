class UniformRandom
  def math; "U(#{@range})"  end
  def name; :uniform_random end
  def desc; "Uniform random number generator in the range of #{@range}" end

  def initialize(range=nil, seed=nil) 
    @seed  = seed || ::Random.new_seed
    @prng  = ::Random.new(@seed)
    @range = range || (0.0..1.0) # TODO: fix range like in code from way back when
  end

  def next; @prng.rand(@range) end
end

Nodus::Pipe.new [Nodus::Proc.new(:uniform_random){          2.0 * Random.rand - 0.5},
                 Nodus::Proc.new(:random_walk   ){|x,state|     [state += x, state]}]


Nodus::Pipe.new [UniformRandom.new(-1.0..1.0),
                 Nodus::Node.new(:random_walk, 0){|x, state| state + x}, # if it gives back one term instead of 2 the output token is doubles as state (so state becomes 'last')
                 Nodus::Node.new(:bid_ask_synth) {|x| {bid: x, ask: x + 12 + (rand(-3.0..3.0))}},
                  ... ]

