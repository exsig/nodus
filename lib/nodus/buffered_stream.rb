require 'securerandom'

module Nodus

  class StreamPath
    attr_reader :path
    # Creates a temporary one if nothing is passed in
    def initialize(path_or_hash=nil)
      path_or_hash ||= "/tmp/#{SecureRandom.uuid}"
      @path = String === path_or_hash ? path_or_hash : "/#{path_or_hash.values.join('/')}"
      @path_a = @path.split('/').compact
    end
    def table_name() "stream_#{@path_a.join('_')}" end
    def temp?() @path_a[0] =~ /^te?mp$/ end
  end

  # Typed, decoupled, overlapping input / output streams that correspond to a single actual signal.
  #
  # Responsibilities
  #   - kind of like a 'Model' in many frameworks- a checkpoint if you will for data-flow processing
  #   - db/persistence layer connection
  #   - automatic table creation / modification
  #   - attaching consumers w/ queries
  #   - ...
  class BufferedStream


  end
end
