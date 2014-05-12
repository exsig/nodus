require 'securerandom'

module Nodus

  class StreamPath
    attr_reader :path
    # Creates a temporary one if nothing is passed in
    def initialize(path_or_hash=nil)
      path_or_hash ||= "/tmp/#{SecureRandom.uuid}"
      @path = String === path_or_hash ? path_or_hash : "/#{path_or_hash.values.join('/')}"
      @path_a = @path.split('/').select{|w| w.present?}
    end
    def table_name() "stream_#{@path_a.join('_')}" end
    def temp?()      !!(@path_a[0] =~ /^te?mp$/)   end
    alias :to_s :path
  end

  module Stores
    class Base

    end

    class Simple < Base
      def initialize(path)
        raise ArgumentError, "Cannot use simple-store for non-temporary or persisted data" unless path.temp?
      end
    end
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
    attr_reader :path_def
    delegate :path, :table_name, :temp?, to: :path_def

    def initialize(path=nil)
      @path_def = StreamPath === path ? path : StreamPath.new(path) # nil value means temporary


    end

  end
end
