# dispatches sound and popup alerts
class Alerter
  constructor: ->
    @popupQueue = []
    @audioBuffers = {}
    @audioContext = new (window.webkitAudioContext || window.AudioContext)

    game.on 'ready', =>
      game.on 'change:combats', @combats, @
      game.on 'closed', @disconnect, @
      game.queue.on 'remove', =>
        if game.queue.length
          @leg()
        else
          @queue()

    for name, channel of game.channels
      channel.on 'add', @chat, @

    socket.on 'message:remy', => @rating 'remy'
    socket.on 'message:gilbert', => @rating 'gilbert'

    prefs.on 'change', (prefs, {changes}) =>
      changes = (change for change of changes)
      return unless changes.length is 1
      [change] = changes
      @play(alert) if (alert = change.match(/(.+)Sound/)?[1])

  play: (type) ->
    volume = prefs.get('volume') * (prefs.get("#{type}Volume") || 0)
    return if volume < 0.01
    audio = prefs.get "#{type}Sound"

    if @audioBuffers[audio]
      source = @audioContext.createBufferSource()
      source.buffer = @audioBuffers[audio]
      gainNode = @audioContext.createGainNode()
      source.connect gainNode
      gainNode.connect @audioContext.destination
      gainNode.gain.value = volume
      source.noteOn 0

    else unless @audioBuffers[audio] == false
      @audioBuffers[audio] = false
      request = new XMLHttpRequest
      request.open 'GET', chrome.extension.getURL("#{audio}.mp3")
      request.responseType = 'arraybuffer'
      request.onload = =>
        @audioContext.decodeAudioData request.response, (buffer) =>
          @audioBuffers[audio] = buffer
          @play type
      request.send()

  popup: (type, content) ->
    return unless prefs.get('popups') && prefs.get("#{type}Popups")
    @popupQueue.push {type, content, time: Date.now()}
    @popupDequeue() unless @popupPending

  popupDequeue: ->
    @popupPending = true
    data = @popupQueue.shift()
    popup = data.content()
    if popup
      popup.img ?= "Icon-48"
      popup.title ?= game.get('character')
      popup.type = 'popup'
      chrome.extension.sendMessage popup, (id) =>
        duration = null
        if prefs.get('popups') && prefs.get("#{data.type}Popups")
          duration = prefs.get("#{data.type}PopupDuration")
          if duration
            since = Date.now() - data.time
            if since > 1000 * 60 * 30
              duration = null
            else if since > 1000 * 60 * 2
              duration = 2000
            else
              duration *= 1000

        chrome.extension.sendMessage {id, duration, type: 'popupDuration'}
        @popupPending = false
        @popupDequeue() if @popupQueue.length
    else
      @popupPending = false
      @popupDequeue() if @popupQueue.length

  chat: (model) ->
    if ! model.get('back') &&
    model.get('name') isnt game.get('character') &&
    (model.get('channel') is 'General' || model.get('type') isnt 'announce') &&
    prefs.get('channels')[model.get('channel')]
      @play 'chat'
      @popup 'chat', ->
        context = model.toJSON()
        context.content = context.content.replace /&lt;|&#60;/g, '<'
        popup = if context.type is 'announce'
          img: "announce"
          title: "Announcement"
          body: Templates['popup/announce'] context
        else
          img: "badge#{model.get('faction')}"
          title: "#{model.get('name')} (#{model.get('channel')})"
          body: Templates["popup/#{model.get('type')}"] context
        if context.name is 'Narbot'
          popup.body = popup.body.
            replace /\[([^\[\]]+) http:\/\/skyrates\.jusque\S+\]\s*$/, '[$1]'
        popup

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
      img = "combat"
      body = Templates["popup/combat"] context
      {img, body}

  disconnect: ->
    @play 'disconnect'
    @popup 'disconnect', ->
      body: Templates['popup/disconnect']()

  rating: (head) ->
    @play 'rating'
    @popup 'rating', ->
      img: head
      body: Templates['popup/rating'] {head}

  # queue completed
  queue: ->
    @play 'queue'
    @popup 'queue', ->
      body: Templates['popup/queue']()

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
      popup = {}
      if context.item
        popup.img = "item#{context.item}"
        popup.body = Templates['popup/tradeLeg'] context
      else
        popup.body = Templates['popup/flightLeg'] context
      popup

