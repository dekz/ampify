$ ->
  Track = Backbone.Model
  
  Album = Backbone.Model.extend
    defaults:
      tracks: []

  Playlist = Backbone.Collection.extend  
    url: '/album'
    model: Album

  # views
  AppView = Backbone.View.extend 
    el: $ '#ampify'

    initialize: () ->
      @collection = new Playlist
      @listenTo @collection, 'add', @addAlbum

      @render()
      
      @collection.add [
        new Album
          id: 3619628392
      ]
      
      @collection.add [
        new Album
          id: 1546934218
      ]


    render: ->
      @$el.html 'waiting for album'
      return this

    addAlbum: (album) ->
      view = new AlbumView {model: album}
      @$el.append view.render().el
      
  AlbumView = Backbone.View.extend
    initialize: ->
      @listenTo @model, 'change', @render
      @model.fetch()

    render: ->
      @$el.html @model.get 'title'
      for track in @model.get 'tracks'
        @$el.append "<div>#{track.streaming_url}</div>"
      return this

  # Instances

  # Tycho - Dive
  # 3619628392

  # Chrome sparks - sparks ep
  # 1546934218

  appView = new AppView