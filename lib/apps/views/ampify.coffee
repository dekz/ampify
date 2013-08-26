$ ->
  # _.templateSettings =
  #   evaluate:    /\{\{#([\s\S]+?)\}\}/g, # {{# console.log("blah") }}
  #   interpolate: /\{\{[^#\{]([\s\S]+?)[^\}]\}\}/g, # {{ title }}
  #   escape:      /\{\{\{([\s\S]+?)\}\}\}/g, # {{{ title }}}

  # Actual Mustache is defined.

  # ###
  # Models and Collections
  # ###
  Track = Backbone.Model.extend
    defaults:
      artist: 'artistName'

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
      console.log album.toJSON()
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

      @player = @$('#audioPlayer')[0]
      @playPauseBtn = @$ '#playPauseBtn'
      @backBtn = @$ '#backBtn'
      @stopBtn = @$ '#stopBtn'
      @forwardBtn = @$ '#forwardBtn'
      @currentlyPlaying = @$ '#currentlyPlaying'

      window.player = @player

    events: ->
      'click #playPauseBtn': 'playPause'

    changeTrack: (track) ->
      # @attributes doesn't work for some reason
      console.log track.toJSON()
      @player.src = track.get 'streaming_url'
      @currentlyPlaying.text track.get 'title'

    playPause: ->
      @playPauseBtn.toggleClass('icon-play')
      @playPauseBtn.toggleClass('icon-pause')

      if @player.paused
        @player.play()
      else
        @player.pause()


  


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
    
    template: """
      {{#playing }}
        <span> * </span>
      {{/playing}}
      <span> {{title}} </span>
    """

    events: ->
      dblclick: 'playTrack'

    render: ->
      @$el.html Mustache.render(@template, @model.attributes)
      return this

    playTrack: ->
      @model.set 'playing', true


  # ---------------------------------------------------------------------

  # KICK IT OFF!
  appView = new AppView
  
  playlist = new Playlist
  playerView = new PlayerView {collection: playlist}
  playlistView = new PlaylistView {collection: playlist}