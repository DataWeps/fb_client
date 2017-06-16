# encoding:utf-8
require 'fb_client/request'
require 'active_support/core_ext/hash/deep_merge'

class FbClient
  module Fetch
    include Request
    FB = {
      :graph_api_url      => "https://graph.facebook.com/v2.2/",
      :sleep_no_token     => 200,
      :sleep_preferred    => 15,
      :token_attempts     => 3,
      :preferred_no_token => 'preferred_sleep',
      :ua => {
        connect: {
          timeout: 60 },
        :attempts => 2,
        :retry_wait   => 5 },
      :errors => {
        :ua_reset   => [5],
        :disable    => [100],
        :break      => [2500, 803, 21],
        :masked     => [190, 613, 2, 4, 17, 613, 32],
        :limit_code => [-3, 1],
        :limit      => [
          /the '?limit'? parameter should not exceed/i,
          /request limit reached/i,
          /an unknown error occurred/i,
          /Please reduce the amount of data you're asking for, then retry your request/],
        user_token: [/unsupported get request/i],
        :different_id => [21] } }.freeze

    class << self
      def fetch_without_token(url, return_error = false)
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
      def fetch(url, preferred = :default, return_error = false, check = false)
        ini_fetch_conf
        token, last_error, doc, attempt = nil, nil, nil, 0
        loop do
          attempt += 1
          break if attempt > @conf[:ua][:attempts]
          token = FbClient::Token.get_token(preferred)

          if !token.nil? && token == @conf[:preferred_no_token]
            sleep(@conf[:sleep_preferred])
            attempt -= 1
            next
          elsif !token.nil? && !token
            sleep(@conf[:sleep_no_token])
            next
          elsif token.nil?
            return nil
          end

          @conf[:graph_api_url] << '/' unless @conf[:graph_api_url].end_with?('/')
          response = request("#{@conf[:graph_api_url]}#{url}" \
            "#{url.index('?') ? '&' : '?'}access_token=#{token}")

          if response && response.include?(:error) && response.include?(:content)
            error = recognize_error(response[:content])
            # stop fetching
            if error.is_a?(Hash) || error == true
              return return_error ? error : false
            # just report token
            else
              FbClient::Token.report_token(token)
              next
            end
          end

          if response && response.is_a?(Hash) && response.include?('error')
            return_error ? { error: response['error'] } : false
          else
            return response
          end
          break
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

      def recognize_error(response)
        response = Oj.load(response) if response.is_a?(String)
        begin
          # limit error - too many items in one response
          if response.include?('error') && response['error'].include?('code')
            if @conf[:errors][:masked].include?(response['code'].to_i) ||
              @conf[:errors][:ua_reset].include?(response['error']['code'].to_i)
              return false
           # elsif disable_page?(response['error'])
           #   { error: :disable }
            elsif @conf[:errors][:break].include?(response['error']['code'].to_i)
              return {:error => response['error']['code']}
            elsif @conf[:errors][:different_id].include?(response['error']['code'].to_i)
              return {
                :error  => response['error']['code'].to_i,
                :new_id => response['error']['message'] =~
                  /to page id (\d+)/i ? $1.to_i : nil
              }
            elsif @conf[:errors][:limit_code].include?(response['error']['code'].to_i)
              return { error: 'limit_error' }
            end
          end

          message = response['error_msg'] || response['error']['message']
          @conf[:errors][:limit].each_with_object(error: message) do |error, mem|
            mem[:error] = 'limit_error' if response['error']['message'].match(error)
          end
        rescue => bang
          { error: "Facebook::Fetch: " \
                    "#{bang.message} #{bang.backtrace} #{response}" }
        end
      end
    end
  end # Fetch
end
