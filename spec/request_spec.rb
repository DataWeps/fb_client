# encoding:utf-8
require 'spec_helper'
require 'fb_client'

describe 'FbClient' do
  context '500 internal' do
    before :context do
      @request = FbClient.fetch('167652014341/feed?limit=250', [:high_priority, :user_token], true)
    end

    it 'request should has error response' do
      expect(@request[:error]).not_to be(nil)
    end
  end

  context 'basic info' do
    before :context do
      @url = 'vilaglatohirmagazin?metadata=1'
      @response = FbClient.fetch(@url, [:high_priority], true)
    end

    it 'should has use 2.3' do
      p @response
      expect(@response['id']).to eq('167654416661674')
    end
  end

  context 'URL fetching' do
    let(:response) do
      FbClient.fetch(
        "#{CGI.escape('http://www.fsfinalword.cz/?page=archive&day=2017-06-12')}" \
        "?fields=engagement,og_object", [:high_priority])
    end

    it 'should has data' do
      expect(response['og_object']['id']).not_to be_empty
    end
  end
end
