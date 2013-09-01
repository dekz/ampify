class Band
  include DataMapper::Resource

  property :id,         String, :key => true
  property :band_id,    String
  property :name,       String
  property :url,        String
  property :subdomain,  String
  has n, :albums
  property :created_at, DateTime
end

class Track
  include DataMapper::Resource

  property :id,         Serial, :key => true
  property :title,      String
  property :band_name,  String
  property :duration,   String
  property :streaming_url,   String, :length => 150
  property :created_at, DateTime
  belongs_to :album
end

class Album
  include DataMapper::Resource

  property :id,           String, :key => true
  property :album_id,     String
  property :title,        String
  property :artist,       String
  property :release_date, String
  property :created_at,   DateTime
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
HOME = File.expand_path(File.join(File.dirname(__FILE__), '../../../'))
DataMapper.setup(:default, "sqlite3://#{File.join(HOME, "/bandcamp.db")}")
DataMapper.auto_upgrade!
