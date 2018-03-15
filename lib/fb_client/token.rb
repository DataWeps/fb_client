# encoding:utf-8
require 'fb_client/request'

module FbClient
  class Token
    TOKEN_TYPES = {
      :default       => 'default',
      :preferred     => 'preferred',
      :high_priority => 'high_priority',
      :old_api       => 'old_api',
      :user_token    => 'user_token' }.freeze

    class << self
      def get_token(type = :default)
        tail = []
        [type].flatten.uniq.each do |one_type|
          tail << "type[]=#{TOKEN_TYPES[one_type]}" if
            TOKEN_TYPES.include?(one_type)
        end
        tail << "type[]=#{TOKEN_TYPES[:default]}" if tail.empty?
        response = request("#{FB_TOKENS[:url]}/get?#{tail.join('&')}")
        return nil if !response || (response.is_a?(Hash) &&
          response.include?(:error))

        response['token'] || response['error']
      end

      # report non-working token
      def report_token(token)
        request("#{FB_TOKENS[:url]}/check?access_token=#{token}")
      end

      # report non-working token and obtain a new one using get_token
      def report_and_get_new_token(token, type = :default)
        report_token token
        get_token type
      end

      def free_token?(type = :default)
        response = request "#{FB_TOKENS[:url]}/stats"
        return false unless response
        return false if response['working'].to_i <= 0
        return false if type == :default && response['preferred'].to_i > 0
        true
      rescue => _
        false
      end

    private

      # initialize curburger client only once
      def ini_token
        @token_conf ||= FB_TOKENS[:ua][:connect]
      end

      def request(url)
        ini_token
        FbClient::Request.ua_get(url, @token_conf)
      end
    end
  end
end
