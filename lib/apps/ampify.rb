require 'yaml'
require 'sinatra'
require 'bandcamp_api'
require 'pry'
require 'haml'
require 'coffee-script'
require 'data_mapper'
require 'dm-sqlite-adapter'
require 'json'
require 'logger'


$sensitive = YAML::load File.read './sensitive.yml'
Bandcamp.config.api_key = $sensitive[:api_key]

configure do
  use Rack::CommonLogger, $stdout
end

configure :development do
    set :logging, Logger::DEBUG
    DataMapper::Logger.new($stdout, :debug)
end

require_relative './models/song'

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
    logger.debug "find album"
    ours = Album.first query
    unless ours
      if query[:album_id]
        album = Bandcamp.get.album query[:album_id]
        # Item doesn't exist
        return nil if album.respond_to? :error and album.error
        band = find_band :band_id => album.band_id
        ours = Album.first :album_id => album.album_id
      end
    end
    ours
  end

  def find_band query
    logger.debug "find band"
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
  haml :app, { :layout => :layout }
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
  Band.all(:name.like => params[:text]).to_json
end

get '/search/all/:text' do
  content_type :json
  text = params[:text]
  result = {
    :albums => Album.all(:title.like => text),
    :bands => Band.all(:name.like => text),
    :tracks => Track.all(:title.like => text)
  }
  result.to_json
end

get '/playlist/:id' do
  content_type :json
  result = Playlist.first(:id => params[:id])
  result.to_json(:methods => [:tracks])
end

post '/playlist/:id' do
  content_type :json
  result = Playlist.first(:id => params[:id])
  body = request.body.read
  if body
    tracks = JSON::parse body
    tracks.each { |id| result.tracks << Track.first(:id => id) }
  end
  result.save
  result.to_json
end

post '/playlist' do
  content_type :json
  result = Playlist.create
  tracks = JSON::parse(request.body.read)
  tracks.each do |id|
    track = Track.first(:id => id)
    result.tracks << track if track
  end
  result.save
  result.to_json
end

delete '/playlist/:id/:track_id' do
  content_type :json
  result = Playlist.first(:id => params[:id])
  result.tracks = result.tracks.delete_if { |t| t.id == Integer(params[:track_id]) }
  result.save
end

delete '/playlist/:id' do
  content_type :json
  result = Playlist.first(:id => params[:id])
  result.destroy
end

