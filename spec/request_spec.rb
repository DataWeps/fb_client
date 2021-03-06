# encoding:utf-8
require 'spec_helper'
require 'webmock/rspec'
require 'fb_client'

describe 'FbClient' do
  context '500 internal' do
    WebMock.allow_net_connect!
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

  describe 'throwed error' do
    describe 'limit reached' do
      before do
        stub_request(:get, /graph/i).to_return(
          status: 400,
          body: File.read(File.join(__dir__, 'webmock/request_spec_request_reached.json')),
          headers: { 'Content-Type' => 'application/json' })
        stub_request(:get, /tokens/i).to_return(
          status: 200,
          body: File.read(File.join(__dir__, 'webmock/request_spec_fb_tokens.json')),
          headers: { 'Content-Type' => 'application/json' })
        allow(FbClient::Token).to receive(:report_token).and_return(true)
      end

      subject(:response) do
        FbClient.fetch('167652014341/feed?limit=250')
      end

      it 'should has' do
        expect(FbClient::Token).to receive(:report_token)
        response
      end
    end
  end

  describe 'break reached' do
    before do
      stub_request(:get, /graph/i).to_return(
        status: 400,
        body: File.read(File.join(__dir__, 'webmock/request_spec_break.json')),
        headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, /tokens/i).to_return(
        status: 200,
        body: File.read(File.join(__dir__, 'webmock/request_spec_fb_tokens.json')),
        headers: { 'Content-Type' => 'application/json' })
    end

    subject(:response) do
      FbClient.fetch('167652014341/feed?limit=250', :default, true)
    end

    it 'should has' do
      expect(response[:error]).to be(2500)
    end
  end
end
