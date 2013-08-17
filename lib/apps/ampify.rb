require 'yaml'
require 'sinatra'
require 'bandcamp_api'
require 'pry'

$sensitive = YAML::load File.read './sensitive.yml'
Bandcamp.config.api_key = $sensitive[:api_key]

get '/artist/:id' do
  Bandcamp.get.band params[:id]
end

get '/search/artist/:text' do
  results = Bandcamp.search params[:text]
  results.map { |r| r.to_json }
end
