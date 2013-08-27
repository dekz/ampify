class Band
  include DataMapper::Resource

  property :id,         Serial
  property :band_id,    String
  property :name,       String
  property :url,        String
  property :subdomain,  String
  has n, :albums
  property :created_at, DateTime
end

class Track
  include DataMapper::Resource

  property :id,         Serial
  property :title,       String
  property :created_at, DateTime
  belongs_to :album
end

class Album
  include DataMapper::Resource

  property :id,         Serial
  property :album_id,   String
  property :title,       String
  property :artist,       String
  property :release_date, String
  property :created_at, DateTime
  has n, :tracks
  belongs_to :band
end

DataMapper.finalize
DataMapper.setup(:default, 'sqlite::memory:')
DataMapper.auto_migrate!
