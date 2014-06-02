require 'helper'
require 'nodus'
require 'nodus/fx'
include Nodus::FX

describe Nodus::FX::Oanda do
  it 'fails when given an unknown source type' do
    ->{Oanda.new(:weird_source)}.must_raise ArgumentError
  end

  let(:oanda_gen) { Oanda.new }

  it 'correctly queries the account' do
    oanda_gen.account_id.to_s.must_match /\w+/
  end

  it 'correctly figures out a bunch of instruments' do
    oanda_gen.instruments.size.must_be :>, 10
  end

  it 'has at least one of the main pairs' do
    symbols = oanda_gen.instruments.map{|i| i.base }
    symbols.must_include :eur
    symbols.must_include :usd
  end
end
