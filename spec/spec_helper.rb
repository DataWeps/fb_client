# encoding:utf-8
require 'rspec'
require 'pry'
require_relative 'fb_tokens'
$: << File.expand_path(File.join(__FILE__, '..', 'lib', 'fb_client'))
ENV['RACK_ENV'] = 'test'

module RSpecMixin
end

RSpec.configure { |c| c.include RSpecMixin }
