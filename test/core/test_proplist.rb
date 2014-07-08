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

  it 'does not confuse absent attributes with nil attributes' do
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
end

