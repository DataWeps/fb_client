require 'fb_client/request'
require 'fb_client/error_response'

require 'active_support/core_ext/hash/deep_merge'

module FbClient
  class Fetch
    FB = {
      :graph_api_url      => "https://graph.facebook.com/v2.9/",
      :sleep_no_token     => 200,
      :sleep_preferred    => 15,
      :token_attempts     => 3,
      :preferred_no_token => 'preferred_sleep',
      :ua => {
        connect: {
          timeout: 60 },
        attempts: 2,
        retry_wait: 5 }
     }.freeze

    class << self
      def fetch_without_token(url, return_error = false)
        ini_fetch_conf
        response = request("#{@conf[:graph_api_url]}#{url}")

        if response && response.include?(:error) && response.include?(:content)
          error = recognize_error(response[:content])
          # stop fetching
          if error.is_a?(Hash) || error == true
            return return_error ? error : false
          end
        end

        if response && response.is_a?(Hash) && response.include?('error')
          return_error ? { error: response['error'] } : false
        end
        response
      end

      # return nil in case of error, data otherwise
      # func - calling method used for logging
      def fetch(url, preferred = :default, return_error = false, _check = false)
        ini_fetch_conf
        token = nil
        attempt = 0
        change_token = 10

        loop do
          attempt += 1
          break if attempt > @conf[:ua][:attempts] || change_token.zero?
          token = FbClient::Token.get_token(preferred)

          if token.present? && token == @conf[:preferred_no_token]
            sleep(@conf[:sleep_preferred])
            attempt -= 1
            next
          elsif !token
            sleep(@conf[:sleep_no_token])
            next
          elsif token.nil?
            return nil
          end

          @conf[:graph_api_url] << '/' unless @conf[:graph_api_url].end_with?('/')
          response = request("#{@conf[:graph_api_url]}#{url}" \
            "#{url.index('?') ? '&' : '?'}access_token=#{token}")

          if FbClient::ErrorResponse.error_response?(response)
            error = FbClient::ErrorResponse.recognize_error(response)
            # stop fetching
            if error[:error] == FbClient::ErrorResponse::MASKED_STATUS
              attempt -= 1
              change_token -= 1
              FbClient::Token.report_token(token)
              next
            end
            return return_error ? error : false
          end

          return response
        end
        false
      end

      def ini_fetch_conf
        return true if defined?(@conf)
        @conf = FbClient::Fetch::FB.dup
        @conf.deep_merge!(FB_CLIENT || {})
      end

      def request(url, params = {})
        ini_fetch_conf
        FbClient::Request.ua_get(
          url, @conf[:ua][:connect].merge(params), @conf[:ua])
      end
    end
  end # Fetch
end
