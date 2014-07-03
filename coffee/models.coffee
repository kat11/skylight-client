class Models.Game extends Backbone.Model
  initialize: ->

    @channels = {}
    for name, id of CHANNELS
      @channels[name] = new Collections.Channel name, id

    @news = new Collections.News @

    socket.on 'open', ->
      session = (match = document.cookie.match(/sessionID=(\d+)/)) &&
        Number(match[1])
      name = $.trim $('#cap .name').text()
      socket.send 'session', session, VERSION, name

    socket.on 'closed', =>
      @closed = true
      @trigger 'closed'

    socket.on 'message:authentication_failure', => socket.close()

    socket.on 'message:personals',
    (squigs, character, faction, wing, location) =>
      location = location || null

      # faction 0 is flight school, 7 is indy
      delete @channels.Faction if faction in [0, 7]

      # wing 0 is no wing
      delete @channels.Wing if wing is 0

      @set {squigs, character, faction, wing, location}
      @checkReady()

    socket.on 'message:combats', (combats) =>
      @set {combats}
      @checkReady()

    socket.on 'message:craft', (craftId, craftName, craftType) =>
      @set {craftId, craftName, craftType}
      @checkReady()

    socket.on 'message:queue', (queue...) =>
      @queue = new Collections.Queue((@get('location') || null), queue)
      @queue.on 'remove', (entry) =>
        @set combats: 0

        if (e = @queue.first()) && (e.get('type') in ['Flight', 'Hunt'])
          @set location: null
        else
          @set location: entry.get('endIsland')

        # need to explicitly request current squigs unless takeoff after trade
        if entry.get('type') in ['Buy', 'Sell'] && @get('location')
          socket.send 'personals'

      @checkReady()

    socket.on 'message:squigs', (squigs) =>
      @set {squigs}

  # check that all essential info has come in and we're ready to start
  checkReady: ->
    return if @ready
    attributes = ['character', 'combats', 'craftId']
    @ready = @queue && _.all attributes, (e) => @has e
    @trigger('ready') if @ready

class Models.Chat extends Backbone.Model
  initialize: ({time, content}) ->
    time = new Date(time * 1000)

    type = if (match = content.match /^\/em (.*)/)
      content = match[1]
      'emote'
    else if (match = content.match /^\/announce (.*)/)
      content = match[1]
      'announce'
    else
      'chat'

    unsanitary = !! content.match /<(?!\/?(i|b|u|font( color=['"][\w#]+['"])?|a( href="\/\/[^\s">]+" target="_blank")?)>)/

    @set {time, content, type, unsanitary}

class Models.Static extends Backbone.Model

class Collections.Channel extends Backbone.Collection
  constructor: (name, id, args...) ->
    @name = name
    @id = id
    super args...

  initialize: ->
    socket.on 'message:more', (id) =>
      return unless id is @id
      @more = true
      @trigger 'more'

    socket.on 'message:static', (id) =>
      if id is @id && ! (@last() instanceof Models.Static)
        @push new Models.Static

    socket.on 'message:backstatic', (id) =>
      if id is @id && ! (@first() instanceof Models.Static)
        @unshift new Models.Static(back: true)

    socket.on 'message:chat',
    (channel, name, title, content, faction, time) =>
      chat = new Models.Chat {
        channel: @name, name, title, content, faction, time
      }

      if channel == @id || chat.get('type') == 'announce'
        @push chat unless chat.get('unsanitary')

    socket.on 'message:backchat',
    (channel, name, title, content, faction, time) =>
      return unless channel == @id
      chat = new Models.Chat {
        channel: @name, name, title, content, faction, time, back: true
      }
      @unshift chat unless chat.get('unsanitary')

  getMore: ->
    return unless @more
    @more = false
    socket.send 'more', @id

class Models.QueueEntry extends Backbone.Model

class Collections.Queue extends Backbone.Collection
  model: Models.QueueEntry

  constructor: (location, list) ->
    now = Date.now()
    startTime = now
    entries = for [endTime, type, a1, a2, b1, b2] in list
      endTime = now + endTime
      entry = {startTime, endTime}
      startTime = endTime

      entry.type = {
        0: 'Flight'
        1: 'Flight'
        2: 'Flight'
        3: 'Flight'
        4: 'Hunt'
        6: 'Buy'
        7: 'Sell'
        8: 'Service'
      }[type]

      [entry.startIsland, entry.endIsland] = switch entry.type
        when 'Flight'
          start = if a2 == 0 then a1 else null
          location = if b2 == 0 then b1 else null
          [start, location]
        when 'Hunt', 'Service'
          location = if b2 == 0 then b1 else null
          [location, location]
        when 'Buy', 'Sell'
          entry.item     = a1
          entry.quantity = a2
          entry.market   = null
          [location, location]
        else
          start = location
          location = null
          [start, location]

      entry

    super entries
    if @length
      setTimeout (=> @update()), 0
      socket.send 'market'
      socket.on 'message:market', @market, @

  update: ->
    now = Date.now()

    if @length && now >= @first().get('endTime')
      @shift().set complete: true

    if @length
      setTimeout =>
        @update()
      , @first().get('remaining') - now

  market: (data...) ->
    marketData = {}
    for [islandId, items] in data
      marketData[islandId] = {}
      for [itemId, val] in items
        marketData[islandId][itemId] = val + 1

    @each (entry) ->
      return unless entry.get('type') in ['Buy', 'Sell']
      market = marketData[entry.get('startIsland')]?[entry.get('item')]
      entry.set {market}

    setTimeout ->
      socket.send('market') if @length
    , 1000 * 60 * 5



class Models.NewsItem extends Backbone.Model
  initialize: ->
    @set time: Date.now()

class Collections.News extends Backbone.Collection
  model: Models.NewsItem

  constructor: (game, args...) ->
    super args...

    game.on 'change:squigs', (game, squigs) =>
      item =
        type: 'squigs'
        value: squigs
      if game.previous('squigs')?
        item.change = squigs - game.previous('squigs')
      @push item

    socket.on 'message:remy', => @push {type: 'rating', head: 'remy'}
    socket.on 'message:gilbert', => @push {type: 'rating', head: 'gilbert'}


