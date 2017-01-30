# encoding:utf-8
require 'typhoeus'

class FbClient
  module Request
    DEFAULT_PARAMS = {
      attempts: 2,
      retry_wait: 3 }.freeze

    def self.ua_get(url, connect_params, params = DEFAULT_PARAMS)
      tries = params[:attempts]
      begin
        response = Typhoeus.get(url, connect_params)
      rescue FetchFailedException => error
        tries -= 1
        return false if tries.zero?
        sleep(params[:retry_wait])
        retry
      end

      return { error: response.return_message, content: response.body } unless
        response.success?

      begin
        Oj.load(response.body)
      rescue SyntaxError, Oj::ParseError => e
        nil
      end
    end
  end
end
