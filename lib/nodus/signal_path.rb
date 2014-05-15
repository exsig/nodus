module Nodus
  class SignalPath
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
end
