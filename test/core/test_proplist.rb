require_relative '../helper.rb'

describe PropSet do
  subject       {    PropSet.new(required: false, type: Fixnum,  desc:   'does stuff', visible: true) }

  class PropSetSub < PropSet
    default weirdy:   'yes'
    inverse visible:  :hidden
    inverse required: :optional
  end

  let(:subclass){ PropSetSub.new(required: false, type: Numeric, visible: true) }

  it 'initialization properties become methods' do
    subject.required.must_equal false
    subject.type.must_equal     Fixnum
    subject.desc.must_equal     'does stuff'
    subject.visible.must_equal  true
  end

  it 'allows adhoc additions to initialized properties' do
    subject.type          = ArgumentError
    subject.type.must_equal ArgumentError
    subject.desc.must_equal 'does stuff'
  end

  it 'allows queries to see if things are specified' do
    subject.has_required?.must_equal true
    subject.has_desc?.must_equal     true
    subject.has_default?.must_equal  false
    subject.default = 1234
    subject.default.must_equal       1234
  end

  it 'correctly emits values for reversed attributes' do
    subclass.visible.must_equal  true
    subclass.hidden.must_equal   false
    subclass.required.must_equal false
    subclass.optional.must_equal true

    subclass.required = true
    subclass.optional.must_equal false
  end

  it 'correctly emits values for bool attribute methods' do
    subclass.visible?.must_equal  true
    subclass.required?.must_equal false
    subclass.optional?.must_equal true
    subclass.type?.must_equal     true
  end

  it 'allows removal of attributes completely' do
    subclass.has_required?.must_equal true
    subclass.no_required            = true
    subclass.has_required?.must_equal false
    subclass.required.must_be_nil
    subclass.optional.must_be_nil
  end

  it 'does not confuse absent with nil-valued' do
    subclass.has_sometimes_nil?.must_equal false
    subclass.sometimes_nil.must_be_nil
    subclass.sometimes_nil = nil
    subclass.has_sometimes_nil?.must_equal true
    subclass.sometimes_nil.must_be_nil
  end

  it 'honors default values (and with reverses)' do
    subclass.has_weirdy?.must_equal false
    subclass.weirdy.must_equal      'yes'

    subclass.weirdy               = 'yes'
    subclass.has_weirdy?.must_equal true
    subclass.weirdy.must_equal      'yes'

    subclass.no_weirdy            = true
    subclass.has_weirdy?.must_equal false
    subclass.weirdy.must_equal      'yes'
    subclass.weirdy?.must_equal     true
  end

  # TODO: check defaults on both keys of inverse pairs
  # TODO: test `realize` and overridden versions
end

describe PropList do
  class MyPropSet < PropSet
    default blah:     20
    default visible:  true
    default required: false
    inverse required: :optional
    inverse visible:  :hidden
    def realize(val)
      self.value   = val
      self.no_blah = true
    end
  end

  subject { PropList.new(MyPropSet) }

  it 'sees default correctly' do
    b = MyPropSet.new({required: true, default: 900}, {name: :some_property})
    b.required.must_equal true
    b.default.must_equal 900
  end

  it 'can be populated an element at a time' do
    subject.add 'some_property', required: true, default: 900
    subject.add :another, :optional, :hidden
    subject.some_property.optional?.must_equal false
    subject[:some_property].default.must_equal 900
    subject.another.optional?.must_equal       true
  end

  it 'can be populated using the << method' do
    subject << [:first_property, :required, {default: 100}]
    subject.first_property.optional?.must_equal    false
    subject.first_property.default.must_equal      100
    subject.first_property.has_default?.must_equal true
    subject.first_property.blah.must_equal         20
  end

  it 'can be turned into a hash' do
    subject.add 'some_property', required: true, default: 900
    subject.add :another, :optional, :hidden
    subject.to_hash.must_be_kind_of Hash
    subject.to_hash.has_key?(:some_property).must_equal true
  end

  it 'allows properties to become realized' do
    subject.add 'prop1', :required, :visible
    subject.add 'prop2', blah: 199, default: 100

    # TODO: add more
  end

  it 'can be merged with another' do
    #a = PropList.new(MyPropSet)
    #a.add(
    skip
  end
end
