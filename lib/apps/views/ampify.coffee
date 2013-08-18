$ ->
  Track = Backbone.Model
  Album = Backbone.Model
  Playlist = Backbone.Collection.extend
    url: '/album'  
    model: Album

  # views
  AppView = Backbone.View.extend 
    el: $ '#ampify'

    initialize: (playlist) ->
      playlist.bind 'add', @addAlbum, this

      @render()
      
      playlist.add [
        new Album
          id: 3619628392
      ]

    render: ->
      @$el.html 'waiting for album'
      return this

    addAlbum: (album) ->
      view = new AlbumView {model: album}
      view.model.fetch 
        success: =>
          console.log this
          @$el.append view.render().el

  AlbumView = Backbone.View.extend
    render: ->
      console.log @model.get 'tracks'
      for track in @model.get 'tracks'
        @$el.append JSON.stringify(track)
      return this

  # Instances

  # Tycho - Dive
  # 3619628392
  appView = new AppView (new Playlist)