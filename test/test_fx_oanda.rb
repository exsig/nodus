require 'helper'
require 'nodus/fx'
include Nodus::FX

describe Nodus::FX::Oanda do
  it 'fails when given an unknown source type' do
    ->{Oanda.new(source: :weird_source)}.must_raise ArgumentError
  end

  let(:oanda_gen) { Oanda.new }

  it 'correctly queries the account' do
    oanda_gen.account_id.to_s.must_match /\w+/
  end

  it 'correctly figures out a bunch of instruments' do
    oanda_gen.instruments.size.must_be :>, 10
  end

  it 'has by default at least one of the main pairs' do
    symbols = oanda_gen.instruments.map{|i| i.base }
    symbols.must_include :eur
    symbols.must_include :usd
  end

  it 'has only specified pairs' do
    o = Oanda.new(pairs: [:eur_usd])
    o.instruments.size.must_equal 1
    o.instruments[0].base.must_equal    :eur
    o.instruments[0].counter.must_equal :usd

    o = Oanda.new(instruments: [:eur_usd])
    o.instruments.size.must_equal 1
    o.instruments[0].base.must_equal    :eur
    o.instruments[0].counter.must_equal :usd

    o = Oanda.new(pairs: [:eur_usd, :usd_chf])
    o.instruments.size.must_equal 2
    syms = o.instruments.map{|i| [i.base, i.counter]}
    syms.must_include [:eur, :usd]
    syms.must_include [:usd, :chf]
  end

end
