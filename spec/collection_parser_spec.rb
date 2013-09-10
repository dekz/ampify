require 'faraday'
require 'json'
require 'pry'
require_relative '../lib/parser/collection'

describe 'Parser' do
  describe 'Colletions' do
    before :all do
      @conn = Faraday.new(:url => 'http://bandcamp.com') do |faraday|
        faraday.response :logger
        faraday.adapter  Faraday.default_adapter
      end
    end

    it 'parse a collection' do
      parsed = Parser::Collection.new(@conn.get('/dekz').body).parse
      parsed.each { |t| t.member?('band_name').should == true }
    end
  end
end
