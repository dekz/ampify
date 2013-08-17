require 'yaml'
require 'sinatra'
require 'bandcamp_api'
require 'pry'
require 'haml'

$sensitive = YAML::load File.read './sensitive.yml'
Bandcamp.config.api_key = $sensitive[:api_key]

get '/' do
  haml :index
end

get '/artist/:id' do
  result = Bandcamp.get.band params[:id]
  haml :artist, :locals => {:artist => result}
end

get '/search/artist/:text' do
  content_type :json
  results = Bandcamp.search params[:text]
  results.map { |r| r.to_json }
end
