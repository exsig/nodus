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

  class Token
    FIELDS = [:physical_ts, :system_ts, :created_ts, :updated_ts, :gen_seqid, :value]
    FIELDS.each do |f|
      define_method(f){ @data[f] }
      define_method("#{f}="){|v| @data[f] = v}
    end

    def initialize(params={})
      @data = {}
      FIELDS.each{|f| @data[f] = params.delete(f)}
      raise ArgumentError, "Unexpected param(s): #{params.inspect} - Accepts: #{FIELDS.inspect}" unless params.blank?
    end

    def [](k)    @data[validated(k)] end
    def []=(k,v) @data[validated(k)] = v end

    private
    def validated(key)
      key = key.to_sym
      raise ArgumentError, "#{key} must be one of: #{FIELDS.inspect}" unless FIELDS.include?(key)
      key
    end
  end

#  module Stores
#    class Base
#
#    end
#
#    class Simple < Base
#      def initialize(path)
#        raise ArgumentError, "Cannot use simple-store for non-temporary or persisted data" unless path.temp?
#        super
#      end
#
#      def 
#    end
#  end

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
