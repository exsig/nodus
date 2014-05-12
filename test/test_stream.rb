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

