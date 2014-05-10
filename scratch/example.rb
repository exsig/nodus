
module Ticks
  class RawStream < Nodus::Stream
    attribute :bid, :ask, :server_timestamp, :volume
    attribute :source, :currency
    # implied session, intrinsic-time, clock-time, idealized-clock-time, generated-clock-time, generator-version, ...
  end

  class Oanda ... ????
end

