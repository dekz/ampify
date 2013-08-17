require 'yaml'
require 'sinatra'
require 'bandcamp_api'
require 'pry'

$sensitive = YAML::load File.read './sensitive.yml'
Bandcamp.config.api_key = $sensitive[:api_key]

get '/artist/:id' do
  content_type :json
  result = Bandcamp.get.band params[:id]
  result.to_json
end

get '/artist/:id/discography' do
  content_type :json
  result = Bandcamp.get.discography params[:id]
  result.to_json
end

get '/track/:id' do
  content_type :json
  result = Bandcamp.get.track params[:id]
  result.to_json
end

get '/album/:id' do
  content_type :json
  result = Bandcamp.get.album params[:id]
  result.to_json
end

get '/search/artist/:text' do
  content_type :json
  results = Bandcamp.search params[:text]
  results.map { |r| r.to_json }
end
