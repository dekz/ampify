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
require 'sidekiq'

require_relative './models/song'

configure do
  sensitive = YAML::load File.read './sensitive.yml'
  Bandcamp.config.api_key = sensitive[:api_key]
  DataModel.connect
end

configure :development do
  set :logging, Logger::DEBUG
  DataMapper::Logger.new($stdout, :debug)
end

require_relative './workers'

helpers do
  def logger
    request.logger
  end

  def bandcamp type, query
    result = Bandcamp.get.send type, query
    # Item doesn't exist
    if result.respond_to? :error and result.error
      logger.debug result.error
      raise result.error
    end
    result
  end

  def populate_band band_id
    PopulateBandJob.perform_async(band_id)
  end

  def find_album query
    logger.debug 'find album'
    ours = Album.first query
    unless ours
      if query[:album_id]
        album = bandcamp :album, query[:album_id]
        band = find_band :band_id => album.band_id
        ours = Album.first :album_id => album.album_id
      end
    end
    ours
  end

  def find_band query
    logger.debug 'find band'
    ours = Band.first query
    unless ours
      if query[:band_id]
        logger.debug "performing bandcmap api lookup on #{query[:band_id]}"
        ours = populate_band query[:band_id]
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
  band.to_json(:exclude => [:created_at])
end

get '/band/:id/discography' do
  content_type :json
  band = find_band :band_id => params[:id]
  band.albums.to_json
end

get '/track/:id' do
  content_type :json
  result = Track.first :id => params[:id]
  result = bandcamp :track, params[:id] unless result
  result.to_json(:exclude => [:created_at])
end

get '/album/:id' do
  content_type :json
  result = find_album :album_id => params[:id]
  result.to_json(:methods => [:tracks], :exclude => [:created_at])
end

get '/search/band/:text' do
  content_type :json
  Band.all(:name.like => params[:text]).to_json(:exclude => [:created_at])
end

get '/search/all/:text' do
  content_type :json
  text = params[:text]
  result = {
    :albums => Album.all(:title.like => text),
    :bands => Band.all(:name.like => text),
    :tracks => Track.all(:title.like => text)
  }

  if result.all? { |key,val| val.empty? }
    bands = bandcamp :search, text
    bands.each do |b|
      ours = populate_band b.band_id
      p ours
    end
  end
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

get '/test' do
  pry binding
end
