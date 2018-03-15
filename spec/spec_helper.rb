# encoding:utf-8
require 'rspec'
require 'pry'
require_relative 'fb_tokens'
$LOAD_PATH << File.expand_path(File.join(__dir__, '../lib/fb_client'))
ENV['RACK_ENV'] = 'test'

module RSpecMixin
end

RSpec.configure { |c| c.include RSpecMixin }
