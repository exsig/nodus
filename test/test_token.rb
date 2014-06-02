require 'helper'
include Nodus

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

describe Nodus::Token do
  it 'rejects invalid fields' do
    fname = rand_word
    while FIELD_NAMES.include?(fname) do fname = rand_word end
    ->{ Token.new(fname => 'val') }.must_raise ArgumentError
  end

  it 'rejects invalid fields even array-style' do
    fname = rand_word
    while FIELD_NAMES.include?(fname) do fname = rand_word end
    t = Token.new
    t.wont_respond_to fname
    ->{ t[fname] }.must_raise ArgumentError
    ->{ t[fname] = 'val' }.must_raise ArgumentError
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

