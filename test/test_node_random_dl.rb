require 'helper'
require 'nodus/nodes/rand_dl'
require 'nodus/nodes/rand_walk'

DL = Nodus::Nodes::Random::DL
Walk = Nodus::Nodes::Random::Walk

describe DL do
  it 'loads correctly' do
    d = DL.new
    d.must_be_instance_of DL
  end

  it 'outputs a bunch of random junk' do
    d = DL.new
    100.times{ d.y.receive.must_be_kind_of Integer }
  end
end

describe Walk do
  it 'outputs a bunch of stuff' do
    w = Walk.new
    1000.times{ puts w.y.receive }
  end
end
