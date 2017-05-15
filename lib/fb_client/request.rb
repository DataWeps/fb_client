# encoding:utf-8
require 'typhoeus'

class FbClient
  module Request
    DEFAULT_PARAMS = {
      attempts: 2,
      retry_wait: 3 }.freeze

    def self.ua_get(url, connect_params, _ = {})
      response = Typhoeus.get(url, connect_params)
      return { error: response.return_message, content: response.body } unless
        response.success?

      begin
        Oj.load(response.body)
      rescue SyntaxError, Oj::ParseError
        nil
      end
    end
  end
end
