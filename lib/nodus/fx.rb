require 'nodus'

module Nodus
  module FX
    def self.const_missing(cname)
      m = "nodus/fx/#{cname.to_s.underscore}"
      require m
      klass = const_get(cname)
      return klass if klass
      super
    end
  end
end
