# encoding:utf-8
require 'fb_client/request'

class FbClient

  module Fetch

    protected

    FB = {
      :graph_api_url      => "https://graph.facebook.com/v2.0/",
      :sleep_no_token     => 200,
      :sleep_preferred    => 15,
      :token_attempts     => 3,
      :preferred_no_token => 'preferred_sleep',
      :ua => {
        :req_timeout  => 60,
        :req_attempts => 2,
        :retry_wait   => 5,
        :req_norecode => true,
        :ignore_kill  => true
      },
      :errors => {
        :ua_reset   => [5],
        :disable    => [100],
        :break      => [2500, 803, 21],
        :masked     => [190, 613, 2, 4, 17, 613],
        :limit_code => [-3, 1],
        :limit      => [
          /the '?limit'? parameter should not exceed/i,
          /an unknown error occurred/i,
          /Please reduce the amount of data you're asking for, then retry your request/
        ],
        :different_id => [21],
      }
    }

    def self.fetch_without_token(url, return_error = false)
      response = request("#{@@conf[:graph_api_url]}#{url}")

      if response && response.include?(:error) && response.include?(:content)
        error = recognize_error response[:content]
        # stop fetching
        return return_error ? error : false if
          error.kind_of?(Hash) || error == true
      end

      if response && response.kind_of?(Hash) && response.include?('error')
        return_error ? {:error => response['error']} : false
      end
      response
    end

    # return nil in case of error, data otherwise
    # func - calling method used for logging
    def self.fetch(url, preferred = :default, return_error = false)
      ini_fetch_conf
      token, last_error, doc, attempt = nil, nil, nil, 0
      loop do
        attempt += 1
        break if attempt > @@conf[:token_attempts]
        token = FbClient::Token.get_token(preferred)

        if !token.nil? && token == @@conf[:preferred_no_token]
          sleep @@conf[:sleep_preferred]
          attempt -= 1
          next
        elsif !token.nil? && !token
          sleep @@conf[:sleep_no_token]
          next
        elsif token.nil?
          return nil
        end

        response = request("#{@@conf[:graph_api_url]}#{url}" \
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

        if response && response.kind_of?(Hash) && response.include?('error')
          return_error ? {:error => response['error']} : false
        else
          return response
        end
        break
      end
      false
    end

    private

    include Request

    def self.ini_fetch_conf
      return true if defined?(@@conf)
      @@conf = FbClient::Fetch::FB
      @@conf.merge!(FB || {})
    end

    def self.request url
      ini_fetch
      FbClient::Request.ua_get @@ua_fetch, url
    end

    # initialize curburger client only once
    def self.ini_fetch
      ini_fetch_conf
      @@ua_fetch ||= Curburger.new(@@conf[:ua])
      @@ua_fetch.reset
    end

    def self.recognize_error response
      begin
        # limit error - too many items in one response
        if response.include?('error') && response['error'].include?('code')
          if @@conf[:errors][:masked].include?(response['code'].to_i) ||
            @@conf[:errors][:ua_reset].include?(response['error']['code'].to_i)
            false
         elsif @@conf[:errors][:disable].include?(response['error']['code'].to_i)
            {:error => response['error']['code'].to_i}
          elsif @@conf[:errors][:break].include?(response['error']['code'].to_i)
            {:error => response['error']['code']}
          elsif @@conf[:errors][:different_id].include?(response['error']['code'].to_i)
            {
              :error  => response['error']['code'].to_i,
              :new_id => response['error']['message'] =~
                /to page id (\d+)/i ? $1.to_i : nil
            }
          elsif @@conf[:errors][:limit_code].include?(response['error']['code'].to_i)
            {
              error: 'limit_error'
            }
          end
        else
          message = response['error_msg'] || response['error']['message']
          limit_error = {:error => message}
          @@conf[:errors][:limit].each { |error|
            limit_error[:error] = 'limit_error' if
              response['error']['message'].match(error)
          }
          limit_error
        end
      rescue => bang
        return {:error => "Facebook::Fetch: " +
          "#{bang.message} #{bang.backtrace} #{response}"
        }
      end
    end
  end # Fetch

end
