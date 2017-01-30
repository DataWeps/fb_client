# encoding:utf-8
require 'oj'

# helper methods
require 'fb_client/token'
require 'fb_client/fetch'

class FbClient
  include Token
  include Fetch
  Oj.default_options = { :mode => :compat, :time_format => :ruby }
  class << self
    def free_token?
      Token.get_token
    end

    def get_token(type = :default)
      Token.get_token(type)
    end

    def report_token token
      Token.report_token(token)
    end

    def report_and_get_new_token(token, type = :default)
      Token.report_and_get_new_token token, type
    end

    def fetch_no_token(url, return_error = false)
      Fetch.fetch_without_token(url, return_error)
    end

    def fetch(url, preferred = :default, return_error = false)
      Fetch.fetch(url, preferred, return_error)
    end
  end
end
