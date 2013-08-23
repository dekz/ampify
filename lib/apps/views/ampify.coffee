$ ->
  _.templateSettings =
    evaluate:    /\{\{#([\s\S]+?)\}\}/g,
    interpolate: /\{\{[^#\{]([\s\S]+?)[^\}]\}\}/g,
    escape:      /\{\{\{([\s\S]+?)\}\}\}/g,

  # ###
  # Models and Collections
  # ###
  Track = Backbone.Model

  Player = Backbone.Model
  
  Album = Backbone.Model.extend
    defaults:
      tracks: []

  AlbumCollection = Backbone.Collection.extend  
    url: '/album'
    model: Album

  Playlist = Backbone.Collection.extend  
    url: '/playlist'
    model: Track


 # --------------------------------------------------------------------

  
  # ###
  # Views
  # ###
  AppView = Backbone.View.extend 
    el: $ '#albums'

    initialize: () ->
      @collection = new AlbumCollection
      @listenTo @collection, 'add', @addAlbum
      @listenTo @collection, 'change', @albumUpdate

      

      @render()
      
      @collection.add [
        new Album
          id: 3619628392 # Tycho - Dive
      ]
      
      @collection.add [
        new Album
          id: 1546934218 # Chrome sparks - sparks ep
      ]


    render: ->
      return this

    addAlbum: (album) ->
      album.fetch()
      albumView = new AlbumView {model: album}
      @$el.append albumView.render().el

    albumUpdate: (album) ->
      for track in album.get 'tracks'
        tm = new Track track
        playlist.add tm
  

  AlbumView = Backbone.View.extend
    initialize: ->
      @listenTo @model, 'change', @render

    render: ->
      @$el.html @model.get 'title'
      return this


  # ----------------------------------------------------------------


  PlayerView = Backbone.View.extend
    el: '#player'

    initialize: ->
      @listenTo @collection, 'change:playing', @changeTrack

    changeTrack: (track) ->
      console.log track
      # @attributes doesn't work for some reason
      @el.src = track.get 'streaming_url'


  PlaylistView = Backbone.View.extend
    el: '#playlist'

    initialize: ->
      @listenTo @collection, 'add', @addTrack

    addTrack: (track) ->
      console.log 'new track', track
      trackView = new TrackView {model: track}
      @$el.append trackView.render().el
      return this


  TrackView = Backbone.View.extend
    initialize: ->
      @listenTo @model, 'change', @render

    template: _.template('<div>{{ title }}</div>')
    
    events: ->
      dblclick: 'playTrack'

    render: ->
      # @$el.html "<div>#{@model.get 'title'}</div>"
      @$el.html @template(@model.attributes)
      return this

    playTrack: ->
      # console.log 'playing', @model.get 'title'
      @model.set 'playing', true


  # ---------------------------------------------------------------------

  # KICK IT OFF!
  appView = new AppView
  
  playlist = new Playlist
  playerView = new PlayerView {collection: playlist}
  playlistView = new PlaylistView {collection: playlist}