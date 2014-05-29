require 'active_support/all'
require 'excon'
require 'json'

# TODO: move to extension location or to main nodus.rb

module Excon
  class Response
    def success?() @status && @status.to_s[0..0] == '2' end
    def payload
      @payload ||= case headers['Content-Type']
                   when 'application/json' then JSON.parse(body)
                     # when 'text/html' then  # TODO: when needed, go ahead and give a parsed html as well (nokogiri or something)
                   else body end
    end
  end

  class Connection
    def basic_url(more_params={})
      p = data.merge(more_params)
      "#{p[:scheme]}://#{p[:host]}/#{p[:path]}"
    end

    Excon::HTTP_VERBS.each do |method|
      class_eval <<-DEF, __FILE__, __LINE__ + 1
        def #{method}!(params={}, &block)
          rsp = #{method}(params, &block)
          raise(IOError, "#{method.to_s.upcase} %s returned a %s : %s" % [basic_url(params), rsp.status, rsp.inspect]) unless rsp.success?
          rsp
        end
      DEF
    end
  end
end


module Nodus
  module FX
    class Oanda < Node
      attr_reader :instruments, :account_id
      def parameterize(source=:production, access_token=nil, instruments=nil)
        @source       = source
        @access_token = access_token

        # TODO: raise error if no ENV['...'] and also none specified and one is needed (i.e., not  sandbox)

        case @source
        when :production
          @access_token ||= ENV['OANDA_ACCESS_TOKEN']
          @api_root       = 'https://api-fxtrade.oanda.com/'
          @stream_root    = 'https://stream-fxtrade.oanda.com/'
        when :practice
          @access_token ||= ENV['OANDA_ACCESS_TOKEN_PRACTICE']
          @api_root       = 'https://api-fxpractice.oanda.com/'
          @stream_root    = 'https://stream-fxpractice.oanda.com/'
        when :sandbox
          error NotImplementedError, "Sandbox Oanda access not implemented- should be easy if you want it."
        else
          error ArgumentError, "Oanda generator source must be one of [:production, :practice, :sandbox]"
        end

        @api_conn = Excon.new(@api_root, headers: {'Authorization' => "Bearer #{@access_token}"}, persistent: true)
        lookup_account()

        # Default to all available instruments if none specified
        @instruments = instruments
        @instruments = lookup_all_instruments() if @instruments.blank?
        @instruments.map!{|i| Instrument.new(i) }

        # Create an output port for each instrument
        @instruments.each{|i| output("#{i.base}_#{i.counter}".to_sym) } # TODO: specify type (when there is one)
      end

      def lookup_account()
        resp        = @api_conn.get!(path: 'v1/accounts', idempotent: true)
        @accounts   = resp.payload['accounts']
        error RuntimeError,        "There are no accounts associated with this auth token (#{resp.payload})"  unless @accounts.present? && @accounts[0].present?
        error NotImplementedError, "Choosing between multiple accounts not implemented"                           if @accounts.size > 1
        # TODO: implement multiple accounts when it comes up- simply choose primary or override w/ a parameter
        @account    = @accounts[0]
        @account_id = @account['accountId']
        error RuntimeError,        "Could not get valid account id (expecting accountId field): #{@accounts}" unless @account_id && @account_id.to_s =~ /\w/
      end

      def lookup_all_instruments()
        @api_conn.get!(path: 'v1/instruments', query: {accountId: @account_id}).payload['instruments']
      end

      state_method :start, :stream

      def start
        # TODO:
        #   - create new generator sessions (?)
        #   - 

        :stream
      end

      def stream
        streamer = ->(chunk, _rem, _tot) do
          # TODO:
          #   - parse json chunk (assume it's always complete...ish?)
          #   - figure out output port to put the data on
          #   - analyze: detect instrument, normalize precision, record wire latency, etc.
          #   - update state and output the data
          #   - watch for unexpected chunks and raise errors if necessary- but recoverable
          #   - possibly change the state based on lack of heartbeats for a given timespan (indicate gaps explicitly)
        end

        # TODO:
        #  - something like:
        #      c = Excon.new('https://stream-fxtrade.oanda.com/v1/prices', headers: h)
        #      q = {accountId: account_id, instruments: 'EUR_USD'}
        #      c.get(query: q, response_block: streamer)
        #      ...
        #   - go to a reconnect state on recoverable exceptions (timeouts, bad chunks from streamer, etc.)
        #   - exponential backoff
        #   - possibly watch for market closings etc.
        #
        :done
      end
    end
  end
end
