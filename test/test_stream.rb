require 'helper'
include Nodus

module SharedPathSpec
  # Some specs shared with StreamPaths and BufferedStreams themselves
  it 'initializes correctly with a normal string' do
    init_path = random_path
    @subject.new(init_path).path.must_equal init_path
    #StreamPath.new(init_path).path.must_equal init_path
  end

  it 'initializes with a hash and maintains ordering' do
    @subject.new(first:  'one', second: 'two', third:   'three').path.must_equal '/one/two/three'
    @subject.new(second: 'two', third: :three, 'first' => 'one').path.must_equal '/two/three/one'
  end

  it 'creates a temp path if none given' do
    @subject.new.path.must_match /^\/tmp\/[\w-]+$/
  end

  it 'creates temp paths that are unique' do
    rand_times(500){@subject.new} # Prime it to a random spot
    several = rand_times{@subject.new.path}
    several.sort.uniq.size.must_equal several.size
    several.each{|sp| sp.must_match /^\/tmp\/[\w-]+$/}
  end

  it 'translates paths into unique table names' do
    table_names = rand_times{@subject.new(random_path).table_name}
    table_names.sort.uniq.size.must_equal table_names.size
    table_names.each{|t| t.must_match /^[\w_-]+$/}
  end

  it 'knows whether or not it is temporary' do
    @subject.new.temp?.must_equal true
    @subject.new(random_path).temp?.must_equal false
  end
end

describe StreamPath do
  include SharedPathSpec
  before do
    @subject = StreamPath
  end

  it 'gives the right path with to_s' do
    init_path = random_path
    @subject.new(init_path).to_s.must_equal init_path
  end
end

describe BufferedStream do
  include SharedPathSpec
  before do
    @subject = BufferedStream
  end
end

# TODO: wrap most of this into a new expectation- something like ".must_have_indifferent_method @subject" or something
module TokenAttrSpec
  it 'can be initialized' do
    Token.new(@subject => sample_dat).must_be_kind_of Token
  end

  it 'is available as a method' do
    Token.new.must_respond_to(@subject)
    Token.new.must_respond_to("#{@subject}=")
  end

  it 'allows one to get the initialized value' do
    val = sample_dat
    t = Token.new(@subject => val)
    t.send(@subject).must_equal val
  end

  it 'can be reset' do
    val = sample_dat
    val2 = sample_dat
    while val == val2 do val2 = sample_dat end
    t = Token.new(@subject => val)
    t.send(@subject).must_equal val
    t.send("#{@subject}=", val2)
    t.send(@subject).must_equal val2
  end

  it 'can be accessed with array notation' do
    val = sample_dat
    Token.new(@subject => val)[@subject].must_equal val
  end

  it 'can be set with array notation' do
    val = sample_dat
    t = Token.new
    t[@subject] = val
    t[@subject].must_equal val
    t.send(@subject).must_equal val
  end
end

FIELD_PAIRS = [
  [:physical_ts, -> { random_datetime }],
  [:system_ts,   -> { random_datetime }],
  [:created_ts,  -> { random_datetime }],
  [:updated_ts,  -> { random_datetime }],
  [:gen_seqid,   -> { rand(6000)      }],
  [:value,       -> { rand(100.0)     }]
]

FIELD_NAMES = FIELD_PAIRS.map(&:first)

FIELD_PAIRS.each do |attribute, gen_proc|
  describe "Token::FIELD[#{attribute}]" do
    before do @subject = attribute end
    define_method(:sample_dat){gen_proc.call}
    include TokenAttrSpec
  end
end

describe Token do
  it 'rejects invalid fields' do
    fname = rand_word
    while FIELD_NAMES.include?(fname) do fname = rand_word end
    ->{ Token.new(fname => 'val') }.must_raise ArgumentError
  end

  it 'initializes multiple fields' do
    pairs = FIELD_PAIRS.sample(100).map{|f,vgen| [f, vgen.call]}
    t = Token.new(Hash[pairs])
    pairs.each do |k, v|
      t.send(k).must_equal v
      t[k].must_equal v
    end
  end
end
