module Nodus
  class Stream
    def initialize(originator)
      @origin = originator
      @seq_id = 0
    end

    def make_new_token
      Nodus::Token.new(self, @seq_id += 1)
    end
  end
end
