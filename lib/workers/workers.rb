require 'sidekiq'
require 'data_mapper'
require 'dm-sqlite-adapter'
require 'bandcamp_api'

$LOAD_PATH.unshift File.expand_path('..', File.dirname(__FILE__))
require 'models/song'

$sensitive = YAML::load File.read './sensitive.yml'
Bandcamp.config.api_key = $sensitive[:api_key]
DataModel.connect

class PopulateBandJob
  include Sidekiq::Worker
  def logger; @logger ||= Logger.new $stdout; end
  def bandcamp type, query
    result = Bandcamp.get.send type, query
    # Item doesn't exist
    if result.respond_to? :error and result.error
      logger.debug result.error
      raise result.error
    end
    result
  end
  def perform band_id
    logger.debug "populating band #{band_id}"

    band   = bandcamp :band, band_id
    if !band.respond_to? :band_id or band.nil?
      logger.info "No such band: #{band_id}"
      return
    end

    disco  = bandcamp :discography, band_id
    if disco.nil?
      logger.info "No such disco: #{band_id}" if disco.nil?
      return
    end

    band = Band.create(:id => band.band_id, :name => band.name , :band_id => band.band_id,
                       :url => band.url, :albums => [])

    # Grab each album that belongs to the band as well
    disco.albums.each do |da|
      next unless da.respond_to? :album_id
      album = bandcamp :album, da.album_id

      a = Album.create(:id => da.album_id, :band => band, :title => album.title, :artist => da.artist,
                       :album_id => da.album_id, :release_date => album.release_date, :tracks => [],
                      )
      a.about = album.about if album.respond_to? :about
      a.url = album.url if album.respond_to? :url
      a.large_art_url = album.large_art_url if album.respond_to? :large_art_url

      # Grab them tracks, not sure how long the streaming urls are valid for
      album.tracks.each do |t|
        logger.debug "#{t.title} #{band.name}"
        puts({:title => t.title, :album => a, :duration => t.duration, :id => t.track_id,
                             :band_name => band.name})
        track = Track.create(:title => t.title, :album => a, :duration => t.duration, :id => t.track_id,
                             :band_name => band.name)
        track.streaming_url = t.streaming_url if t.respond_to? :streaming_url
        track.save
        a.tracks.push track
      end
      a.save
      band.albums.push a
    end
    band.save
    band
  end
end
