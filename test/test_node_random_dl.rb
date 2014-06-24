require 'helper'
require 'nodus/nodes/rand_dl'

DL = Nodus::Nodes::Random::DL

describe DL do
  it 'loads correctly' do
    d = DL.new
    d.must_be_instance_of DL
  end

  it 'outputs a bunch of random junk' do
    d = DL.new
    100.times{ puts d.y.receive }
  end
end
