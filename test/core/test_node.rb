require_relative '../helper.rb'
include Nodus::Nodes

module MiniTest::Assertions
  def assert_kind_of_node(obj)
    assert obj.kind_of_node?, "expected #{obj} to be a class descended from Node"
  end
end
Object.infect_an_assertion :assert_kind_of_node,
                           :must_be_a_node,
                           :only_one_argument

describe Nodus::Nodes::Node do
  subject do
    Node.compose(:subject) do
      param :p1, :required
      param :p2,  default: 10
      param :p3, :optional, default: 100
    end
  end

  it 'is a node, with correct name' do
    subject.must_be_a_node
    subject.new.must_be_kind_of Node
    subject.name.must_equal :subject
  end

  it 'has the correct parameters' do
    subject.parameters.keys.sort.must_equal [:p1, :p2, :p3]
    subject.parameters.p3.default.must_equal 100
  end

  it 'ensures that there is a name' do
    ->{Node.compose()}.must_raise ArgumentError
  end
end

describe Nodus::Nodes::ConcurrentNode do
  let(:base_1) do
    Node.compose(:base_1) do
      param :p1, :required
      param :p2,  default: 10
      param :p3, :optional, default: 100
    end
  end
  let(:base_2){ Node.compose(:base_2){ [:p4,:p5,:p6].each{|p| param p} }}
  let(:base_3){ Node.compose(:base_3){ [:p1,:p2,:p3].each{|p| param p, default: 20} }}

  it 'is a kind of node' do
    conc = ConcurrentNode.compose(:conc, base_1, base_2)
    conc.must_be_a_node
    conc.new.must_be_kind_of Node
  end

  it 'non-conflicting consolidated params act normal' do
    skip
  end

  it 'non-conflicting params can also be accessed with parent specifier' do
    skip
  end

  it 'can have its parameters curried ala basenode' do
    skip
  end
end
