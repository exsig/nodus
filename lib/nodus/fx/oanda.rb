require 'nodus/fx'

module Nodus
  module FX
    class Oanda < Nodus::Node
      PARAMS = {production: {access_var:  'OANDA_ACCESS_TOKEN',
                             api_root:    'https://api-fxtrade.oanda.com/',
                             stream_root: 'https://stream-fxtrade.oanda.com/'},
                practice:   {access_var:  'OANDA_ACCESS_TOKEN_PRACTICE',
                             api_root:    'https://api-fxpractice.oanda.com/',
                             stream_root: 'https://stream-fxpractice.oanda.com/'}}

      def defaults() PARAMS[@source] || {} end

      def parameterize(opts={})
        @manual_start = true
        @source       = opts.delete(:source)       || :production
        error NotImplementedError, "Sandbox Oanda access not implemented- should be easy if you want it." if @source == :sandbox
        error ArgumentError,       "Oanda generator source must be one of [:production, :practice, :sandbox]" unless defaults.present?
        @access_token = opts.delete(:access_token) || (defaults[:access_var].blank? ? nil : ENV[defaults[:access_var]])
        error ArgumentError,       "No access_token specified. Can also put in env: #{PARAMS.map{|_,d|d[:access_var]}.join(' and/or ')}" if @access_token.blank? && @source != :sandbox
        @api_root     = opts.delete(:api_root)     || defaults[:api_root]
        @stream_root  = opts.delete(:stream_root)  || defaults[:stream_root]
        @account_id   = opts.delete(:account_id)   # will get looked up later if needed and not specified here

        # Default to all available instruments if none specified
        @requested_instruments =  opts.delete(:instruments) || opts.delete(:pairs)
        instruments.each{|i| output("#{i.base}_#{i.counter}".to_sym) } # TODO: specify type (when there is one)
      end

      private def api_conn
        @api_conn ||= Excon.new(@api_root, headers: {'Authorization' => "Bearer #{@access_token}"}, persistent: true)
      end

      def all_available_instruments
        @all_available_instruments ||= api_conn.get!(path: 'v1/instruments', query: {accountId: account_id}).payload['instruments']
      end

      def account_id
        return @account_id unless @account_id.blank?
        resp     = api_conn.get!(path: 'v1/accounts', idempotent: true)
        accounts = resp.payload['accounts']
        error RuntimeError,        "There are no accounts associated with this auth token (#{resp.payload})"  unless accounts.present? && accounts[0].present?
        error NotImplementedError, "Choosing between multiple accounts not implemented"                           if accounts.size > 1
        # TODO: implement multiple accounts when it comes up- simply choose primary or override w/ a parameter
        a_id = accounts[0]['accountId']
        error RuntimeError, "Could not get valid account id (expecting accountId field): #{accounts}" unless a_id && a_id.to_s =~ /\w/
        @account_id = a_id
      end

      def instruments
        return @instruments unless @instruments.blank?
        @instruments = @requested_instruments || all_available_instruments
        @instruments.map!{|i| Instrument.new(i) } # Normalize / Ensure class
      end

      state_method :start, :stream

      # TODO: way to specify that it is a 'registered' generator for some stream/streams
      #
      def start
        # TODO:
        #   - create new generator sessions (?)
        #   - 
        #
        @session.close if @session
        @session = Nodus::Session.new

        :stream
      end

      def stream
        streamer = ->(chunk, _rem, _tot) do
          p chunk
          # TODO:
          #   - parse json chunk (assume it's always complete...ish?)
          #   - figure out output port to put the data on
          #   - analyze: detect instrument, normalize precision, record wire latency, etc.
          #   - update state and output the data
          #   - watch for unexpected chunks and raise errors if necessary- but recoverable
          #   - possibly change the state based on lack of heartbeats for a given timespan (indicate gaps explicitly)
        end

        @stream_conn = Excon.new(@stream_root, headers: {'Authorization' => "Bearer #{@access_token}"}, persistent: true)
        query = {accountId: account_id, instruments: instruments.map(&:to_oanda_id).join(',')}
        begin
          @stream_conn.get(path: 'v1/prices', query: query, response_block: streamer)

          # TODO:
          #   - go to a reconnect state on recoverable exceptions (timeouts, bad chunks from streamer, etc.)
          #   - exponential backoff
          #   - possibly watch for market closings etc.
          #
        end

        :done
      end
    end
  end
end
