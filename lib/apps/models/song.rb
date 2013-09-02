require 'dm-core'
require 'dm-timestamps'
class Band
  include DataMapper::Resource

  property :id,         String, :key => true
  property :band_id,    String
  property :name,       String, :length => 150
  property :url,        String, :length => 150
  property :subdomain,  String
  has n, :albums
  property :created_at, DateTime, :default => DateTime.now
end

class Track
  include DataMapper::Resource

  property :id,         String, :key => true, :length => 15
  property :title,      String, :length => 150
  property :band_name,  String, :length => 150
  property :duration,   String
  property :streaming_url,   String, :length => 150
  property :created_at, DateTime, :default => DateTime.now
  belongs_to :album
end

class Album
  include DataMapper::Resource

  property :id,           String, :key => true
  property :album_id,     String
  property :title,        String, :length => 150
  property :artist,       String
  property :release_date, String
  property :created_at, DateTime, :default => DateTime.now
  has n, :tracks
  belongs_to :band
end

class Playlist
  include DataMapper::Resource
  property :id, Serial
  property :created_at, DateTime
  has n, :tracks, :through => Resource
end

DataMapper.finalize
DataMapper::Model.raise_on_save_failure = true
HOME = File.expand_path(File.join(File.dirname(__FILE__), '../../../'))
DataMapper.setup(:default, "sqlite3://#{File.join(HOME, "/bandcamp.db")}")
DataMapper.auto_upgrade!
