$ ->
  AppView = Backbone.View.extend 
    el: $ '#ampify'

    initialize: ->
      playlist.fetch()
      @render()

    render: ->
      @$el.html 'i school MCs cause im the motherfuckin dean'
      return this


  Track = Backbone.Model.extend
    defaults: ->
      grep: 'something'
  
  Playlist = Backbone.Collection.extend
    model: Track
    url: '/album/3619628392'

  playlist = new Playlist
  appView = new AppView

  console.log playlist