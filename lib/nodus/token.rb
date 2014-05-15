module Nodus
  class Token
    FIELDS = [:physical_ts, :system_ts, :created_ts, :updated_ts, :gen_seqid, :value, :session]
    FIELDS.each do |f|
      define_method(f){ @data[f] }
      define_method("#{f}="){|v| @data[f] = v}
    end

    # Token.new(params={k: v, ...})
    # Token.new(value)
    # Token.new(value, predecessor)
    # Token.new(value, predecessor, overrides)
    #
    # other_token.next(new_value, overrides={})
    def initialize(params={})
      #case params
      #when nil, Hash
        @data = {}
        FIELDS.each{|f| @data[f] = params.delete(f)}
        raise ArgumentError, "Unexpected param(s): #{params.inspect} - Accepts: #{FIELDS.inspect}" unless params.blank?
      #when 
      #end
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
end
