$:.unshift(File.expand_path('../lib', File.dirname(__FILE__)))
$:.unshift(File.expand_path('./spec/support'))

describe 'API' do
  before :all do
    @conn = Faraday.new(:url => 'http://localhost:5000') do |faraday|
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end
  end

  it 'should get an album' do
    resp = @conn.get '/albums/1546934218'
    p resp
  end

end
