
module Nodus
  def_exception :InstrumentNameError,  "Unrecognized instrument (currency pair) name or type: %s", ArgumentError

  module FX
    class Instrument
      attr_reader :base, :counter

      def initialize(*args)
        @opts = (Hash === args.last ? args.pop : {})
        name_params = args
        name_params = @opts['instrument'] if name_params.blank?
        @base, @counter = Instrument.normalized_name(*name_params)
        @pip_unit = @opts.delete(:pip) || @opts.delete(:pip_unit)
      end

      def self.normalized_name(*name)
        name = name.pop if name.size == 1
        if Array === name && name.size == 2
          name.map do |c|
            c = c.to_s.strip.downcase
            error InstrumentNameError, name.pretty_inspect unless c =~ /^[a-z]{3}$/
            c.to_sym
          end
        elsif String === name
          pair_characters = name.each_char.select{|c| c =~ /[A-Za-z]/}
          error InstrumentNameError, name.pretty_inspect unless pair_characters.size == 6
          normalized_name(pair_characters[0..2].join, pair_characters[3..5].join)
        elsif Instrument === name
          [name.base, name.counter]
        else
          error InstrumentNameError, name.pretty_inspect
        end
      end
    end
  end
end
