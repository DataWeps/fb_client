# encoding:utf-8
require 'fb_client/request'

class FbClient

  module Token

    TOKEN_TYPES = {
      :default       => 'default',
      :preferred     => 'preferred',
      :high_priority => 'high_priority',
      :old_api       => 'old_api',
      :user_token    => 'user_token',
    }

    def self.get_token(type = :default)
      tail     = []
      [type].flatten.uniq.each { |one_type|
        tail << "type[]=#{TOKEN_TYPES[one_type]}" if
          TOKEN_TYPES.include?(one_type)
      }
      tail << "type[]=#{TOKEN_TYPES[:default]}" if tail.empty?
      response = request "#{FB_TOKENS[:url]}/get?#{tail.join('&')}"
      return nil if !response || (response.kind_of?(Hash) &&
        response.include?(:error))

      response['token'] || response['error']
    end

    # report non-working token
    def self.report_token token
      request "#{FB_TOKENS[:url]}/check?access_token=#{token}"
    end

    # report non-working token and obtain a new one using get_token
    def self.report_and_get_new_token token, type = :default
      report_token token
      get_token type
    end

    def self.free_token?(type = :default)
      begin
        response = request "#{FB_TOKENS[:url]}/stats"
        return false unless response
        return false if response['working'].to_i <= 0
        return false if type == :default && response['preferred'].to_i > 0
        true
      rescue => bang
        return false
      end
    end

    private

    include Request

    # initialize curburger client only once
    def self.ini_token
      @@ua_token ||= Curburger.new((FB_TOKENS[:ua] || {}).merge({
        :ignore_kill  => true,
        :req_norecode => true,
      }))
      @@ua_token.reset
    end


    def self.request url
      ini_token
      FbClient::Request.ua_get @@ua_token, url
    end

  end

end
