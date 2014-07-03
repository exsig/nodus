require_relative '../helper.rb'

describe Enumerator do
  it 'exposes a to_node method' do
    Enumerator.public_instance_methods.must_include :to_node
  end
end

describe 'simple generator' do
  it 'can be created from an enumerator' do
    gen = (1..10).each.to_node
    gen.must_be_kind_of Nodus::Node
  end

  it 'emits tokens' do
    gen = (1..10).each.to_node
    t1 = gen.receive
    t2 = gen.receive
    t1.must_be_kind_of Nodus::Token
    t2.must_be_kind_of Nodus::Token
    t1.wont_equal t2
  end

  it 'gives an end-of-stream signal instead of a token when appropriate' do
    gen = (1..3).each.to_node
    (1..3).each{ gen.receive.wont_be_kind_of Nodus::EndOfStream }
    gen.receive.must_be_kind_of Nodus::EndOfStream
  end
end
