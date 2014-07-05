require_relative '../helper.rb'
require 'ostruct'

describe FlexHash do
  it 'can be initialized like a hash' do
    h = FlexHash.new(name: 'hello', blah: 'there!')
    h.must_be_instance_of FlexHash
    h.size.must_equal 2
  end

  it 'can be be initialized with an array' do
    h = FlexHash.new([:one, 1, :two, 2])
    h.must_be_instance_of FlexHash
    h.size.must_equal 2
  end

  it 'can be initialized with an array shorthand' do
    h = FlexHash[:one, 1, :two, 2]
    h.must_be_instance_of FlexHash
    h.size.must_equal 2
  end

  it 'can be initialized with a non-flat array shorthand' do
    h = FlexHash[[:one, 1], [:two, 2]]
    h.must_be_instance_of FlexHash
    h.size.must_equal 2
  end

  subject { FlexHash.new(a: 100, b: 101, c: 102, d: 103) }

  it 'can be accessed with methods' do
    subject.a.must_equal 100
    subject.d.must_equal 103
  end

  it 'can be accessed with symbols' do
    subject[:a].must_equal 100
    subject[:b].must_equal 101
  end

  it 'can be accessed with strings' do
    subject['a'].must_equal 100
    subject['c'].must_equal 102
  end

  it 'accumulates more methods' do
    subject[:hmmmmm] = 500
    subject[:a].must_equal 100
    subject[:hmmmmm].must_equal 500
    subject.hmmmmm.must_equal 500
  end

  it 'allows modifying of original values' do
    subject[:a] = 200
    subject[:a].must_equal 200
    subject[:d].must_equal 103
    subject.a.must_equal 200
  end

  it 'allows position-based access of values' do
    subject[0].must_equal 100
    subject[3].must_equal 103
    subject[4].must_equal nil
  end

  it 'acts more like a hash than OpenStruct tends to' do
    subject.shift.must_equal [:a, 100]
  end

end

describe FlexArray do
  it 'seems to work' do
    a = FlexArray.new
    a << OpenStruct.new(name: 'howdy')
    a[1] = OpenStruct.new(name: :duty)
    a << OpenStruct.new(name: 123)

    a[0].name.must_equal       'howdy'
    a['howdy'].name.must_equal 'howdy'
    pp a.howdy
    a.howdy.name.must_equal    'howdy'
    a[/d/].map{|os| os.name.to_s}.sort.must_equal ['duty', 'howdy']
    a[2].must_be_kind_of OpenStruct
  end

  # TODO: test for real
end
