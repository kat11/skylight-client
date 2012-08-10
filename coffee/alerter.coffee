# dispatches sound and popup alerts
class Alerter
  constructor: ->
    @popupQueue = []

    game.on 'ready', =>
      game.on 'change:combats', @combats, @
      game.on 'closed', @disconnect, @
      game.queue.on 'remove', =>
        if game.queue.length
          @leg()
        else
          @queue()

    socket.on 'message:remy', => @rating 'remy'
    socket.on 'message:gilbert', => @rating 'gilbert'

    prefs.on 'change', (prefs, {changes}) =>
      changes = (change for change of changes)
      return unless changes.length is 1
      [change] = changes
      @play(alert) if (alert = change.match(/(.+)Sound/)?[1])

  play: (type) ->
    mp3 = prefs.get "#{type}Sound"
    volume = prefs.get('volume') * (prefs.get("#{type}Volume") || 0)
    if volume > 0.01
      try
        url = chrome.extension.getURL "#{mp3}.mp3"
        audio = new window.Audio url
        audio.volume = volume
        audio.play()
      catch e
        null

  popup: (type, content) ->
    return unless prefs.get('popups') && prefs.get("#{type}Popups")
    @popupQueue.push {type, content, time: Date.now()}
    @popupDequeue() unless @popupPending

  popupDequeue: ->
    @popupPending = true
    data = @popupQueue.shift()
    chrome.extension.sendMessage {type: 'popupRequest'}, (id) =>
      if prefs.get('popups') && prefs.get("#{data.type}Popups")
        duration = prefs.get("#{data.type}PopupDuration")
        if duration
          since = Date.now() - data.time
          if since > 1000 * 60 * 30
            data = null
          else if since > 1000 * 60
            duration = 1
        if data
          data.duration = duration * 1000
          data.content = data.content()
      else
        data = null

      chrome.extension.sendMessage {id, data, type: 'popupContent'}
      @popupPending = false
      @popupDequeue() if @popupQueue.length

  chat: (view) ->
    if ! view.model.get('back') &&
    view.model.get('name') isnt game.get('character') &&
    prefs.get('channels')[view.model.get('channel')]
      @play 'chat'
      @popup 'chat', ->
        Handlebars.templates["popup/chat"]
          channel: view.model.get('channel')
          faction: view.model.get('faction')
          content: view.html

  combats: ->
    @combatTime = time = Date.now()
    return unless game.get('combats')
    @play 'combat'

    leg = game.queue.first()
    return unless leg && leg.get('endIsland') &&
      leg.get('type') in ['Flight', 'Hunt']

    @popup 'combat', =>
      return null unless @combatTime == time && game.queue?.first() == leg
      context = _.extend game.toJSON(), leg.toJSON()
      Handlebars.templates["popup/combat"] context

  disconnect: ->
    @play 'disconnect'
    @popup 'disconnect', ->
      Handlebars.templates['popup/disconnect'] game.toJSON()

  rating: (head) ->
    @play 'rating'
    @popup 'rating', ->
      Handlebars.templates['popup/rating'] _.extend(game.toJSON(), {head})

  # queue completed
  queue: ->
    @play 'queue'
    @popup 'queue', ->
      Handlebars.templates['popup/queue'] game.toJSON()

  # started a new queue leg
  leg: ->
    @play 'leg'

    leg = game.queue.first()
    @popup 'leg', ->
      return null unless game.queue.first() is leg
      context = _.extend game.toJSON(), leg.toJSON()
      context.action = switch context.type
        when 'Flight'
          'flying to'
        when 'Hunt'
          'hunting around'
        when 'Service'
          'servicing at'
        when 'Buy'
          'buying'
        when 'Sell'
          'selling'
      Handlebars.templates['popup/leg'] context
