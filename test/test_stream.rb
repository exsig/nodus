require 'helper'
include Nodus
describe StreamPath do
  it 'initializes correctly with a normal string' do
    init_path = random_path
    StreamPath.new(init_path).path.must_equal init_path
  end

  it 'initializes with a hash and maintains ordering' do
    StreamPath.new(first:  'one', second: 'two', third:   'three').path.must_equal '/one/two/three'
    StreamPath.new(second: 'two', third: :three, 'first' => 'one').path.must_equal '/two/three/one'
  end

  it 'creates a temp path if none given' do
    StreamPath.new.path.must_match /^\/tmp\/[\w-]+$/
  end

  it 'creates temp paths that are unique' do
    rand_times(500){StreamPath.new} # Prime it to a random spot
    several = rand_times{StreamPath.new.path}
    several.sort.uniq.size.must_equal several.size
    several.each{|sp| sp.must_match /^\/tmp\/[\w-]+$/}
  end

  it 'translates paths into unique table names' do
    table_names = rand_times{StreamPath.new(random_path).table_name}
    table_names.sort.uniq.size.must_equal table_names.size
    table_names.each{|t| t.must_match /^[\w_-]+$/}
  end
end
