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

  it 'is a node, with correct title' do
    subject.must_be_a_node
    subject.new.must_be_kind_of Node
    subject.title.must_equal :subject
  end

  it 'has the correct parameters' do
    subject.parameters.keys.sort.must_equal [:p1, :p2, :p3]
    subject.parameters.p3.default.must_equal 100
  end

  it 'ensures that there is a title' do
    ->{Node.compose()}.must_raise ArgumentError
    ->{Node[]}.must_raise         ArgumentError
  end

  it 'children having children having children' do
    ssubject = subject.compose(:ssubject)
    ssubject.must_be_a_node
    ssubject.parameters.keys.sort.must_equal [:p1, :p2, :p3]
    ssubject.parameters.p3.default.must_equal 100

    sssubject = ssubject.compose(:sssubject){ param :p4 }
    sssubject.must_be_a_node
    sssubject.parameters.keys.sort.must_equal [:p1, :p2, :p3, :p4]
    sssubject.parameters.p3.default.must_equal 100
  end

  it 'can be done using a more natural class syntax' do
    class MySuperNode < Node.compose :my_super_node
      param :p2, :hidden
    end
    MySuperNode.must_be_a_node
    MySuperNode.parameters.p2.hidden?.must_be_true
    remove_class(:MySuperNode)

    class MyOtherNode < subject.compose :my_other_node
      param :pzz
    end
    MyOtherNode.must_be_a_node
    MyOtherNode.parameters.pzz.must_be_kind_of Param
    remove_class(:MyOtherNode)

    class MyThirdNode < Node[:the_third]; end
    MyThirdNode.must_be_a_node
    MyThirdNode.parameters.must_be_empty
    #pp MyThirdNode
    MyThirdNode.title.must_equal :the_third

    remove_class(:MyThirdNode)
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
    conc.title.must_equal :conc
  end

  it 'also requires a title (for now)' do
    ->{ConcurrentNode.compose(base_1, base_2)}.must_raise ArgumentError
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
