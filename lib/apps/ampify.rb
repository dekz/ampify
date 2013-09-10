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
require 'faraday'
$LOAD_PATH.unshift File.expand_path('..', File.dirname(__FILE__))

require 'models/song'
require 'parser/collection'
require 'workers/workers'

configure do
  sensitive = YAML::load File.read './sensitive.yml'
  Bandcamp.config.api_key = sensitive[:api_key]
  DataModel.connect
end

configure :development do
  set :logging, Logger::DEBUG
  DataMapper::Logger.new($stdout, :debug)
end


helpers do
  def logger
    request.logger
  end

  def bandcamp type, query
    result = Bandcamp.get.send type, query
    # Item doesn't exist
    if result.respond_to? :error and result.error
      logger.debug result.error_message
      raise result.error_message
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
        album = bandcamp :album, query[:album_id] rescue halt 404
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
    bandcamp(:search, text).each { |b| populate_band b.band_id }
    # Come back later
    return 202
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

get '/user/:user/collections' do
  content_type :json
   @conn = Faraday.new(:url => 'http://bandcamp.com') do |faraday|
     faraday.adapter  Faraday.default_adapter
   end
  parsed = Parser::Collection.new(@conn.get(params[:user]).body).parse
  parsed = parsed.map do |i|
    { :title => i['featured_track_title'], :id => i['featured_track'], :duration => i['featured_track_duration'],
      :band_name => i['band_name'], :album_id => i['tralbum_id']
    }
  end
  JSON.dump parsed
end
