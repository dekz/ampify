require 'faraday'
require 'json'

describe 'API' do
  before :all do
    host = ENV['AMPIFY_HOST'] || 'http://localhost:5000'
    puts host
    @conn = Faraday.new(:url => host) do |faraday|
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
    band = JSON.parse resp.body
    band['name'].should == "Chrome Sparks"
  end

  it 'can populate' do
    bands = [
      #'3037729624',
      '687693559',
      '432335280',
      '2595713091'
    ]
    bands.each do |b|
      resp = @conn.get "/band/#{b}"
      band = JSON.parse resp.body
      puts band
    end
  end

end
