require 'faraday'
require 'json'

describe 'API' do
  before :all do
    @conn = Faraday.new(:url => 'http://localhost:5000') do |faraday|
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end
  end

  it 'should get an album' do
    resp = @conn.get '/album/1546934218'
    album = JSON.parse resp.body
    album['title'].should == "Sparks EP"
    album['artist'].should == "Chrome Sparks"
  end

  it 'should get a band' do
    resp = @conn.get '/band/3025875313'
    album = JSON.parse resp.body
    album['name'].should == "Chrome Sparks"
  end

end
