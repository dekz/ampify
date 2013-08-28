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

  def populate_band band_id
    result = Bandcamp.get.band band_id
    disco = Bandcamp.get.discography band_id
    ours = Band.create(:name => result.name , :band_id => result.band_id , :url => result.url)

    albums = []
    disco.albums.each do |da|
      next unless da.respond_to? :album_id
      album = Bandcamp.get.album da.album_id
      a = Album.create(:band => ours, :title => album.title, :artist => da.artist,
                       :album_id => da.album_id, :release_date => album.release_date)
      a.tracks = album.tracks.map do |t|
        track = Track.create(:title => t.title, :album => a, :duration => t.duration)
        if t.respond_to? :streaming_url
          track.streaming_url = t.streaming_url
        end
        track.save
        track
      end
      a.save
      a
    end
    ours.albums = albums
    ours.save
    ours
  end

  def find_album query
    ours = Album.first query
    unless ours
      if query[:album_id]
        album = Bandcamp.get.album query[:album_id]
        band = find_band :band_id => album.band_id
        ours = Album.first :album_id => album.album_id
      end
    end
    ours
  end

  def find_band query
    ours = Band.first query
    unless ours
      if query[:band_id]
        logger.debug "performing bandcmap api lookup on #{query[:band_id]}"
        ours = populate_band query[:band_id]
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
  result = find_album :album_id => params[:id]
  result.to_json(:methods => [:tracks])
end

get '/search/band/:text' do
  content_type :json
  results = Bandcamp.search params[:text]
  results.map { |r| r.to_json }
end

get '/search/all/:text' do
  content_type :json
  result = {}
  text = params[:text]
  result[:albums] = Album.all(:title.like => text)
  result[:bands] = Band.all(:name.like => text)
  result[:tracks] = Track.all(:title.like => text)
  result.to_json
end
