require 'helper'
require 'nodus/fx'
include Nodus::FX

PUNCT = %Q{ *@\•^†‡°″¡¿#№÷ºª%‰+−‱¶′″‴§~_|‖¦©℗®℠™⁂❧☞‽⸮◊※⁀⁀«»„”[](){}⟨⟩:,،、‒–—―…...!.‐-?‘’“”'";/⁄·  & }.chars.uniq + [' ']*100

def rand_pseudo_currency
  3.times.map{Randgen.char}.join
end

def rand_currencies(&block)
  rand_poisson.times do
    @base           = rand_pseudo_currency
    @counter        = rand_pseudo_currency
    @base_symbol    = @base.downcase.to_sym
    @counter_symbol = @counter.downcase.to_sym
    i = yield
    i.counter.must_equal @counter_symbol
    i.base.must_equal    @base_symbol
  end
end

describe Nodus::FX::Instrument do
  it 'can be initialized with separate strings' do
    rand_currencies{ Instrument.new(@base, @counter) }
  end
  
  it 'can be initialized with separate symbols' do
    rand_currencies{ Instrument.new(@base.to_sym, @counter.to_sym) }
  end

  it 'can be initialized with pair symbol' do
    ' -_/'.each_char{|d| rand_currencies{ Instrument.new("#{@base}#{d}#{@counter}".to_sym) }}
  end

  it 'can be initialized with an existing instrument' do
    rand_currencies{ Instrument.new(Instrument.new(@base,@counter)) }
  end

  it 'can be initialized with a concatenated string' do
    rand_currencies{ Instrument.new("#{@base}#{@counter}") }
  end

  it 'can be initialized with misc punctuation' do
    ' -_/'.each_char{|d| rand_currencies{ Instrument.new("#{@base}#{d}#{@counter}") }}
  end

  it 'can be initialized with lots of punctuation' do
    rand_currencies{ Instrument.new("#{@base}#{PUNCT.sample(rand_poisson(4))}#{@counter}") }
  end

  it 'returns the oanda id properly formatted' do
    i = Instrument.new(:'eur/usd')
    i.to_oanda_id.must_equal 'EUR_USD'
  end
end
