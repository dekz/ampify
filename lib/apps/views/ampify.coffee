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
      band_name: ''

  Player = Backbone.Model

  Discography = Backbone.Model.extend
    defaults:
      band_id: ''
      albums: []

    url: ()->
      return "/band/#{@get 'band_id'}/discography"

    parse: (resp, xhr) ->
      albums = []
      _.each resp, (album) ->
        albums.push new Album album
      return { albums: albums }

  Band = Backbone.Model.extend
    select: ->
      @trigger 'select', this

    defaults:
      band_id: ''
      name: ''
      url: ''

  Album = Backbone.Model.extend
    url: () ->
      return "/album/#{@get 'id'}"
    select: ->
      @trigger 'select', this

    defaults:
      tracks: []

  Search = Backbone.Model.extend
    defaults:
      bands: []
      albums: []
      tracks: []
      query: ''

    url: () ->
      return "/search/all/#{@get 'query'}"

    parse: (resp, xhr) ->
      results = {bands: [], albums: [], tracks: []}

      _.each resp.bands, (bandDetails) ->
        results.bands.push new Band bandDetails
      _.each resp.albums, (albumDetails) ->
        results.albums.push new Album albumDetails
      _.each resp.tracks, (trackDetails) ->
        results.tracks.push new Track trackDetails

      return results

    selectAlbum: (album) ->
      @trigger 'selectAlbum', album
    selectBand: (band) ->
      @trigger 'selectBand', band


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
    el: $ '#playlists'

    initialize: () ->
      @collection = new AlbumCollection
      @listenTo @collection, 'add', @addAlbum
      @listenTo @collection, 'change', @albumUpdate

      @searcher = new Search
      @listenTo @searcher, 'selectAlbum', @addToPlaylist
      @listenTo @searcher, 'selectBand', @addBandToPlaylist
      @searchView = new SearchView { model: @searcher }

      @render()

      @collection.add [
        new Album
          id: 3619628392 # Tycho - Dive
      ]

      # @collection.add [
      #   new Album
      #     id: 1546934218 # Chrome sparks - sparks ep
      # ]


    addToPlaylist: (album) ->
      @collection.add [
        album
      ]

    addBandToPlaylist: (band) ->
      disco = new Discography { band_id: band.get 'id' }
      co = @collection
      disco.fetch({
        success: () ->
          for album in disco.get 'albums'
            co.add [
              album
            ]
      })



    render: ->
      return this

    addAlbum: (album) ->
      console.log 'album added'
      album.fetch()
      albumView = new AlbumView {model: album}
      @$el.append albumView.render().el

    albumUpdate: (album) ->
      console.log album.toJSON()
      for track in album.get 'tracks'
        tm = new Track track
        playlist.add tm



  SearchView = Backbone.View.extend
    el: $ '#search'

    initialize: ->
      @input = @$ '#searchInput'
      @results = @$ '#searchResults'
      @resultsBands = @$ '#searchResults .searchResultsBands'
      @resultsAlbums = @$ '#searchResults .searchResultsAlbums'
      @resultsTracks = @$ '#searchResults .searchResultsTracks'

      @listenTo @model, 'change:bands', @renderBandResults
      @listenTo @model, 'change:albums', @renderAlbumResults
      @listenTo @model, 'change:tracks', @renderTrackResults

    events:
      'change #searchInput': 'search'
      'focusout': 'hideResults'
      'focusin': 'renderAllResults'

    renderAllResults: ->
      @renderBandResults(@model)
      @renderAlbumResults(@model)
      @renderTrackResults(@model)

    renderBandResults: (search) ->
      @$('.band-result').remove()
      @results.dropdown()

      for band in search.get 'bands'
        bv = new BandResultView {model: band}
        @listenTo band, 'select', @selectBand
        @resultsBands.after bv.render().el

      @results.show()

    renderAlbumResults: (search) ->
      @$('.album-result').remove()
      @results.dropdown()

      for album in search.get 'albums'
        av = new AlbumResultView {model: album}
        @listenTo album, 'select', @selectAlbum
        @resultsAlbums.after av.render().el

      @results.show()

    renderTrackResults: (search) ->
      @$('.track-result').remove()
      @results.dropdown()

      for track in search.get 'tracks'
        tv = new TrackResultView {model: track}
        @resultsTracks.after tv.render().el

      @results.show()

    hideResults: ->
      @results.hide()

    search: ->
      @model.set 'query', @input.val()
      @model.fetch()

    selectBand: (band) ->
      @model.selectBand band
      @results.toggle()

    selectAlbum: (album) ->
      @model.selectAlbum album
      @results.toggle()

  BandResultView = Backbone.View.extend
    el: '<li class="band-result" role="presentation">'

    template: '<a role="menuitem">{{name}}</a>'

    events: ->
      mousedown: 'select'

    render: ->
      @$el.html Mustache.render(@template, @model.attributes)
      return this

    select: ->
      @model.select()

  AlbumResultView = Backbone.View.extend
    el: '<li class="album-result" role="presentation">'

    template: '<a role="menuitem">{{title}}</a>'

    events: ->
      mousedown: 'select'

    render: ->
      @$el.html Mustache.render(@template, @model.attributes)
      return this

    select: ->
      @model.select()

  TrackResultView = Backbone.View.extend
    el: '<li class="track-result" role="presentation">'

    template: '<a role="menuitem">{{title}}</a>'

    events: ->
      mousedown: 'select'

    render: ->
      @$el.html Mustache.render(@template, @model.attributes)
      return this

    select: ->
      console.log 'touched track', @model


  # ----------------------------------------------------------------

  CurrentlyPlayingView = Backbone.View.extend
    el: '#currentlyPlaying'

    initialize: ->
      @listenTo @collection, 'change:playing', @changeTrack

      @title = $ '#currentlyPlayingTitle'
      @time = $ '#currentlyPlayingTime'
      @player = $('#audioPlayer')[0]
      @player.addEventListener 'ended', => @trackEnded()
      @player.addEventListener 'timeupdate', => @timeUpdate()
      @progress = $('#progress .slider')
      @progress.slider({
        'tooltip': 'hide',
        'max': 100,
        'value': 0,
      }).on 'slide', (ev) => @seek(ev.value)
      window.slider = @progress
      @reset()

    reset: ->
      @title.text ''
      @time.text ''
      @progress.slider('setValue', 0)
      $('#progress').hide()

    titleTemplate:
      '<a role="menuitem" href="#track/{{id}}">
         <i class="text-center currently-playing">{{title}} - {{band_name}}</i>
       </a>'
    renderTitle: (track) ->
      @title.html Mustache.render(@titleTemplate, track.attributes)

    changeTrack: (track) ->
      @renderTitle track
      $('#progress').show()

    seek: (pct) ->
      @player.currentTime = @player.duration * (pct / 100)

    timeUpdate: ->
      pct = (@player.currentTime / @player.duration) * 100
      @time.text "#{@player.currentTime} / #{@player.duration}"
      @progress.slider('setValue', pct)

  PlayerView = Backbone.View.extend
    el: '#player'

    initialize: ->
      @listenTo @collection, 'change:playing', @changeTrack

      @player = @$('#audioPlayer')[0]
      @player.addEventListener 'ended', => @nextTrack()

      @volume = @$('#volume .slider')
      @volume.slider({
        'tooltip': 'hide',
        'max': 100,
        'value': 75,
      }).on 'slide', (ev) ->
        $('#audioPlayer')[0].volume = (ev.value / 100)

      @playPauseBtn = @$ '#playPauseBtn'
      @prevBtn = @$ '#prevBtn'
      @stopBtn = @$ '#stopBtn'
      @nextBtn = @$ '#nextBtn'
      @previous = []

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




  AlbumView = Backbone.View.extend
    initialize: ->
      @listenTo @model, 'change', @render

    template: """
      <a href="#" class="thumbnail">
        <img src="{{large_art_url}}" >
        <span class="list-group-item">{{title}} </span>
      </a>
    """

    render: ->
      @$el.html Mustache.render(@template, @model.attributes)
      return this

  BandView = Backbone.View.extend
    el: '#bandInfo'
    initialize: ->
      @listenTo @collection, 'change:playing', @render

    template: """
      <a href="{{url}}" class="thumbnail">
        <img src="{{large_art_url}}" >
        <span class="list-group-item"> {{artist}} - {{title}} </span>
      </a>
      {{about}}
    """

    render: (track) ->
      album = new Album { id: track.get 'album_id' }
      album.fetch({
        success: () =>
          @$el.html Mustache.render(@template, album.attributes)
      })
      #@$el.html Mustache.render(@template, album.attributes)
      return this


  PlaylistView = Backbone.View.extend
    el: '#playlist'

    initialize: ->
      @listenTo @collection, 'add', @renderTrack
      @listenTo @collection, 'reset', @render

    render: ->
      # makes it so only one redraw occurs per add
      @$el.empty()
      container = document.createDocumentFragment()

      @collection.each (track) ->
        trackView = new TrackView {model: track}
        container.appendChild trackView.render().el

      @$el.append container
      return this

    renderTrack: (track) ->
      trackView = new TrackView {model: track}
      @$el.append trackView.render().el
      return this



  TrackView = Backbone.View.extend
    tagName: 'tr'

    initialize: ->
      @listenTo @model, 'change', @render

    template: """
      <td class="badge-td">
        {{#playing }}
        <span class="badge">  <i class="icon-music"/> </span>
        {{/playing}}
      </td>
      <td>
        <span>{{title}}</span>
      </td>
      <td>
        <span>{{band_name}}</span>
      </td>
      <td>
        <span>{{duration}}</span>
      </td>
    """

    events: ->
      dblclick: 'playTrack'

    render: ->
      @$el.html Mustache.render(@template, @model.attributes)
      return this

    playTrack: ->
      @model.set 'playing', true

  Collection = Backbone.Collection.extend
    model: Album

    initialize: () ->
      @_meta = {}

    meta: (prop, value) ->
      # I don't freaking want nulls so value? sucks
      if typeof value isnt 'undefined'
        return @_meta[prop] = value
      else
        return @_meta[prop]

    url: ()->
      console.log @_meta
      return "/user/#{@meta 'user'}/collections"

  CollectionRouter = Backbone.Router.extend
    routes:
      "playlist/:value": "loadPlaylist"
      "album/:value": "loadAlbum"
      "track/:value": "loadTrack"
      "band/:value": "loadBand"
      "*actions": "defaultRoute"

  # ---------------------------------------------------------------------

  # KICK IT OFF!
  appView = new AppView

  window.playlist = playlist = new Playlist
  playerView = new PlayerView {collection: playlist}
  playlistView = new PlaylistView {collection: playlist}
  currentlyPlayingView = new CurrentlyPlayingView {collection: playlist}
  bandView = new BandView { collection: playlist }

  collectionRouter = new CollectionRouter

  collectionRouter.on 'route:defaultRoute', (actions) ->
    c = new Collection
    c.meta('user', actions)
    @listenTo c, 'change', (a) ->
      console.log a.get 'band_name'
      for track in a.get 'tracks'
        playlist.add track
    c.fetch
      success: () ->
        for item in c.models
          item.fetch()

  collectionRouter.on 'route:loadBand', (value) ->
    c = new Discography { band_id: value }
    playlist.reset()
    @listenTo c, 'change', (a) ->
      for album in a.get 'albums'
        @listenTo album, 'change', (ab) ->
          for track in album.get 'tracks'
            playlist.add track
        album.fetch()
    c.fetch
      success: () ->

  Backbone.history.start()
