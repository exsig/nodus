
class Array
  def *(b_array)
    self.map do |a|
      if Array === a
        h,t = a
        [h,t.to_a * b_array.to_a]
      else
        [a,b_array]
      end
    end
    #out = []
    #self.map do |a|
    #  a = [a] unless Array === a
    #  tail = a.pop
    #  b_array.map{|b| [tail, b]}
    #  #b_array.each{|b| out << (a + [b])}
    #end
    #out
  end
end



sources       = [ :oanda, :truefx, :'forex.com', :dukascopy ]
signals = [ :bid, :ask, :delta_time ]
signal_aliasing = [ :intrinsic, :physical_simple, :physical_interval ]

#derivs        = [:none]
#(1..2).each{|order| (0..4).each{|lag| derivs <<  "fd(#{order},#{2**lag})"}}

derivs = [:none, 'fd(1-3,0-9) *30']
# Cascading finite-diff? (a sort of decomposition)?

all_signals = sources * signals * signal_aliasing * derivs


#lagging_central_tendencies = [ 'ewma*20', 'ewmm*20'
# central_smoothers = 
# decompositions = central_smoothers + [

#decompositions = [ :ewma, :ewmm, :staticext, :extenvelope ]

#features      = [ :ewma


require 'pp'
#pp derivs
PP.pp(sources * signals * signal_aliasing * derivs, $>, 190)

#pp [:a,:b] * [:c, :d, :e] * [:x, :y]
