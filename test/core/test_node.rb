require_relative '../helper.rb'
include Nodus::Nodes

module MiniTest::Assertions
  def assert_kind_of_node(obj) assert obj.kind_of_node?, "expected #{obj} to be a class descended from Node" end
end
Object.infect_an_assertion :assert_kind_of_node, :must_be_a_node, :only_one_argument


describe Nodus::Nodes::Node do

end

describe Nodus::Nodes::ConcurrentNode do
  let(:base_1) do
    Class.new(Node) do
      param :p1, :required
      param :p2, default: 10
      param :p3, :optional, default: 100
    end
  end

  let(:base_2) do
    Class.new(Node) do
      param :p4
      param :p5
      param :p6
    end
  end

  let(:base_3) do
    Class.new(Node) do
      param :p1
      param :p2, default: 20
    end
  end

  it 'is a kind of node' do
    base_1.must_be_a_node
    base_2.must_be_a_node
    base_3.must_be_a_node

    conc = ConcurrentNode.compose(base_1, base_2)
    conc.must_be_a_node
  end

  it 'consolidates all parameters' do
    skip
  end

  it 'can have its parameters curried ala basenode' do
    skip
  end
end
