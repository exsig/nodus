require 'excon'
require 'json'

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

