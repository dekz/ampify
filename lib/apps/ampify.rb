require 'yaml'
require 'sinatra'
require 'bandcamp_api'
require 'pry'
require 'haml'
require 'coffee-script'
require 'data_mapper'
require 'dm-sqlite-adapter'

require_relative './models/song'

$sensitive = YAML::load File.read './sensitive.yml'
Bandcamp.config.api_key = $sensitive[:api_key]

use Rack::Logger

helpers do
  def logger
    request.logger
  end

  def find_band query
    ours = Band.first query
    unless ours
      if query[:band_id]
        logger.debug "performing bandcmap api lookup on #{query[:band_id]}"
        result = Bandcamp.get.band query[:band_id]
        disco = Bandcamp.get.discography query[:band_id]
        ours = Band.create(:name => result.name , :band_id => result.band_id , :url => result.url)
        ours.albums = disco.albums.map do |da|
          album = Bandcamp.get.album da.album_id
          a = Album.create(:band => ours, :title => album.title, :artist => da.artist,
                       :album_id => album.album_id, :release_date => album.release_date,)
          a.tracks = album.tracks.map do |t|
                       Track.create(:title => t.title, :album_id => a.album_id)
                     end
          pry binding
          a
        end
        ours.save
      else
        logger.debug "can't find band by #{query}"
      end
    end
    ours
  end
end

get '/' do
  haml :app, {
    :layout => :layout
  }
end

get '/js/ampify.js' do
  coffee :ampify
end

get '/band/:id' do
  content_type :json
  band = find_band :band_id => params[:id]
  band.to_json
end

get '/band/:id/discography' do
  content_type :json
  band = find_band :band_id => params[:id]
  result = Bandcamp.get.discography params[:id]
  pp result
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
