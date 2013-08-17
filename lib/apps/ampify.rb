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

get '/band/:id' do
  result = Bandcamp.get.band params[:id]
  haml :band, {
    :locals => {:band => result},
    :layout => :layout
  }
end

get '/band/:id/everything' do
  band = Bandcamp.get.band params[:id]
  disco = Bandcamp.get.discography params[:id]
  albums = disco.instance_exec { @albums }

  album_tracks = albums.map {|album| Bandcamp.get.album album.album_id}

  # pry binding

  haml :band, {
    :locals => {
      :band => band,
      :disco => disco,
      :tracks => album_tracks,
      :albums => albums
    },
    :layout => :layout
  }
end


get '/band/:id/discography' do
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

get '/search/band/:text' do
  content_type :json
  results = Bandcamp.search params[:text]
  results.map { |r| r.to_json }
end
