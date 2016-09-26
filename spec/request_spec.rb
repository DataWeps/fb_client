# encoding:utf-8
require 'spec_helper'
require 'fb_client'

describe 'FbClient' do
  context '500 internal' do
    before :context do
      @request = FbClient.fetch('167652014341/feed?limit=250', [:high_priority], true)
    end

    it 'request should has error response' do
      expect(@request[:error]).not_to be(nil)
    end
  end

  context 'basic info' do
    before :context do
      @url = 'vilaglatohirmagazin?metadata=1'
      p FbClient.fetch(@url, [:high_priority], true)
    end

    it 'should has use 2.3' do
    end
  end
end
