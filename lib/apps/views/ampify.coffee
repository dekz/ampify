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

    nextTrack: (track) ->
      next = @at(@indexOf(track) + 1)
      if next
        return next
      else
        return @first()

    prevTrack: (track) ->
      prev = @at(@indexOf(track) - 1)
      if prev
        return prev
      else
        return @last()

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

      @searchView = new SearchView


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


  SearchView = Backbone.View.extend
    el: $ '#search'

    initialize: ->
      @$el.typeahead {
        name: 'ampify'
        local: [
          'yeah'
          'what'
          'okay'
        ]
      }

    events:
      change: 'search'

    search: ->
      console.log @$el.val()

  # ----------------------------------------------------------------


  PlayerView = Backbone.View.extend
    el: '#player'

    initialize: ->
      @listenTo @collection, 'change:playing', @changeTrack

      @player = @$('#audioPlayer')[0]
      @playPauseBtn = @$ '#playPauseBtn'
      @prevBtn = @$ '#prevBtn'
      @stopBtn = @$ '#stopBtn'
      @nextBtn = @$ '#nextBtn'
      @currentlyPlaying = @$ '#currentlyPlaying'
      @previous = []

      window.player = @player

    events:
      'click #playPauseBtn': 'playPause'
      'click #nextBtn': 'nextTrack'
      'click #prevBtn': 'prevTrack'

    trackReady: ->
      unless @currentTrack
        @collection.first().set 'playing', true
        return false
      return true

    togglePlay: ->
      if @player.paused
        @playPauseBtn.removeClass('icon-pause')
        @playPauseBtn.addClass('icon-play')
      else
        @playPauseBtn.removeClass('icon-play')
        @playPauseBtn.addClass('icon-pause')

    changeTrack: (track) ->
      prev = _.last(@previous)
      
      if prev?
        prev.set('playing', false)

      @previous.push track
      @currentTrack = track

      @player.src = track.get 'streaming_url'
      @currentlyPlaying.text track.get 'title'
      @player.play()
      @togglePlay()

    playPause: ->
      if @trackReady()
        if @player.paused
          @player.play()
        else
          @player.pause()
        @togglePlay()

    nextTrack: ->
      @collection.nextTrack(@currentTrack).set 'playing', true

    prevTrack: ->
      @collection.prevTrack(@currentTrack).set 'playing', true




  PlaylistView = Backbone.View.extend
    el: '#playlist'

    initialize: ->
      @listenTo @collection, 'add', @render
    
    render: ->
      # makes it so only one redraw occurs per add
      @$el.empty()
      container = document.createDocumentFragment()

      @collection.each (track) ->
        trackView = new TrackView {model: track}
        container.appendChild trackView.render().el

      @$el.append container
      return this


  TrackView = Backbone.View.extend
    initialize: ->
      @listenTo @model, 'change', @render

    template: """
      {{#playing }}
        <i class="icon-music"/>
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

  window.playlist = playlist = new Playlist
  playerView = new PlayerView {collection: playlist}
  playlistView = new PlaylistView {collection: playlist}
