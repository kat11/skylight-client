Views.timestamp = (d, showSeconds) ->
  pad = (num) -> if ('' + num).length is 1 then '0' + num else num
  str = ['Sun', 'Mon', 'Tues', 'Wednes', 'Thurs', 'Fri', 'Satur'][d.getDay()]
  str += "day #{pad d.getHours()}:#{pad d.getMinutes()}"
  str += ":#{pad d.getSeconds()}" if showSeconds
  str

class Views.Switcher extends Backbone.View
  id: 'skylightSwitcher'

  events:
    click: 'switch'

  initialize: ->
    @$el.prependTo '#content'
    @render()

  render: ->
    @$el.html Templates[@id] prefs.toJSON()
    @

  switch: ->
    prefs.set active: !prefs.get('active')
    true

class Views.Style extends Backbone.View
  tagName: 'style'

  initialize: ->
    @render()
    @$el.appendTo 'head'

  render: ->
    @$el.html Templates.style()
    @

class Views.Skylight extends Backbone.View
  id: 'skylight'

  events:
    'click .showOptions': -> @optionsView.show()

  initialize: ->
    new Views.Style

    $('#client *').remove()
    @$el.appendTo '#client'
    @render()

    for status in ['closed', 'ready']
      if game[status] then @[status]() else game.on status, @[status], @

  render: ->
    @$el.html Templates[@id] {MAX_TEXTBOX}
    @

  ready: ->
    new Views.News
    new Views.Window
    new Views.Queue
    channels = new Views.Channels
    new Views.Textbox {channels}
    @optionsView = new Views.Options
    @$('.intro').addClass 'hide'

  closed: ->
    @$('.intro').html "Unable to connect"
    new Views.Disconnected

class Views.Channels extends Backbone.View
  el: "#skylight .channels"

  initialize: ->
    index = 0
    channels = []
    for name of CHANNELS
      if (collection = game.channels[name])
        do =>
          channel = new Views.Channel {collection}
          channel.index = index++
          channel.on 'selected', => @show channel
          channel.select() unless @current
          channels.push channel

    Mousetrap.bind 'alt+ctrl+left', =>
      index = @current.index - 1
      channels[index].select() if index >= 0
      false

    Mousetrap.bind 'alt+ctrl+right', =>
      index = @current.index + 1
      channels[index].select() if index < channels.length
      false

    socket.on 'message:online', (online) => @feedback "#{online} online"

    messages =
      rating_success: "rating sent"
      rating_unknown: "unknown rating recipient"
      rating_limited: "out of ratings for today"
      rating_restricted: "skyrates raises an eyebrow"

    for event, feedback of messages
      do (feedback) =>
        socket.on "message:#{event}", => @feedback feedback

    prefs.on 'change:textarea', =>
      setTimeout =>
        @current?.scrollDown()
      , 0

  show: (channel) ->
    if @current is channel
      channel.scrollDown()
      return

    if @current
      @current.deselect()
      if channel.index < @current.index
        channel.$el.addClass 'left'
      else
        channel.$el.addClass 'right'

    @current = channel
    @$el.append channel.el
    setTimeout ->
      channel.$el.removeClass 'left right'
      channel.scrollDown()
    , 0

    @trigger 'change'

  feedback: (string) ->
    @current?.feedback string

class Views.Channel extends Backbone.View
  className: 'channel'

  events:
    'click .more': 'getMore'

  initialize: ->
    @id   = @collection.id
    @name = @collection.name

    @tab = new Views.ChannelTab {@name}
    @tab.on 'select', => @select()

    @render()

    @more = @$ '.more'

    @collection.on 'more', => @moreAvailable()
    @moreAvailable() if @collection.more

    @collection.on 'add', (model) =>
      if model instanceof Models.Chat && ! model.get('back')
        @tab.highlight() unless model.get('back')
      @addModel model, model.get('back')

    @collection.each (model) =>
      @addModel model

    @init = true

  render: ->
    @$el.html Templates.channel()
    @tab.render()
    @

  select: ->
    @tab.select()
    @trigger 'selected'

  deselect: ->
    @tab.deselect()

  addModel: (model, top) ->
    type = _.find ['Chat', 'Static'], (klass) ->
      model instanceof Models[klass]

    if type
      el = new Views[type]({model}).render().el
      if top
        @prepend el
      else
        @append el

  append: (el) ->
    $el = $ el
    @$el.append el

    if @init && @tab.selected && $el.position().top <= @$el.height() + 6
      @scrollDown()
      setTimeout ->
        $el.addClass 'show'
      , 0
    else
      $el.addClass 'show'

  prepend: (el) ->
    $el = $ el
    $el.insertAfter(@more).addClass 'show'
    if @tab.selected
      @$el.scrollTop @$el.scrollTop() + $el.innerHeight()

  getMore: ->
    @collection.getMore()
    @more.addClass 'hide'

  moreAvailable: ->
    @more.show().removeClass 'hide'

  scrollDown: ->
    last = @$ '> *:last'
    target = @$el.scrollTop() - @$el.height() +
      last.position().top + last.innerHeight()
    target = 0 if target < 0
    @$el.scrollTop target

  feedback: (string) ->
    view = new Views.Feedback {string}
    @append view.render().el

class Views.ChannelTab extends Backbone.View
  tagName: 'li'

  events:
    click: -> @trigger 'select'

  initialize: ->
    @render()
    $("#skylight .tabs").append @el
    letter = @options.name[0].toLowerCase()
    Mousetrap.bind "alt+ctrl+#{letter}", =>
      @trigger 'select'
      false

  render: ->
    @$el.html @options.name
    @

  select: ->
    @selected = true
    @$el.removeClass 'highlight'
    @$el.addClass 'selected'

  deselect: ->
    @selected = false
    @$el.removeClass 'selected'

  highlight: ->
    @$el.addClass 'highlight' unless @selected

class Views.Textbox extends Backbone.View
  el: '#skylight .textbox'

  events:
    'keypress input':    'inputKeypress'
    'keypress textarea': 'textareaKeypress'

  initialize: ->
    @input     = @$ 'input'
    @textarea  = @$ 'textarea'
    @channels  = @options.channels
    @render()
    @focus()

    prefs.on 'change:rptag', @render, @
    prefs.on 'change:textarea', (prefs, textarea) =>
      if textarea
        @textarea.val @input.val()
      else
        @input.val @textarea.val()
      @render()
    @channels.on 'change', @render, @

  render: ->
    placeholder = game.get 'character'
    if @channels.current?.name is 'Roleplay' && prefs.get 'rptag'
      placeholder += " #{prefs.get 'rptag'}"
    @input.attr {placeholder}
    @textarea.attr {placeholder}
    @$el.toggleClass 'textarea', prefs.get('textarea')
    @

  focus: ->
    if prefs.get 'textarea'
      @textarea.focus()
    else
      @input.focus()

  inputKeypress: (event) ->
    @keypress event.keyCode, @input

  textareaKeypress: (event) ->
    @keypress event.keyCode, @textarea

  keypress: (keyCode, field) ->
    return unless keyCode is 13 # enter/return key

    str = $.trim field.val()
    field.val ''

    return unless str

    if (match = str.match(/^\/online\s*$/i))
      socket.send 'online'
    else if (match = str.match(/^\/(hon|honou?r|gil|gilbert)\s+(\S.*?)\s*$/i))
      socket.send 'rating', match[2], true
    else if (match = str.match(/^\/(inf|infamy|remy)\s+(\S.*?)\s*$/i))
      socket.send 'rating', match[2], false
    else
      channel = @channels.current
      rptag = prefs.get 'rptag'
      if rptag && channel.name is 'Roleplay'
        str = if (match = str.match(/^\/(ooc|ignore) |^\/\S+$/))
          str
        else if (match = str.match(/^(\/\S+)(.+)/))
          "#{match[1]} #{rptag}#{match[2]}"
        else
          "#{rptag} #{str}"
      socket.send 'chat', channel.id, str

    false # stop keypress event bubbling

class Views.Chat extends Backbone.View
  className: 'chat'

  attributes: ->
    title: Views.timestamp(@model.get('time'), true)

  initialize: ->
    content = @model.get 'content'
    template = if (match = content.match /^\/em (.*)/)
      content = match[1]
      'emote'
    else if (match = content.match /^\/announce (.*)/)
      content = match[1]
      'announce'
    else
      'chat'
    @html = Templates["chat/#{template}"] _.extend(@model.toJSON(), {content})
    alerter.chat @

  render: ->
    @$el.html @html
    @

class Views.Static extends Backbone.View
  className: 'chat static'

class Views.Feedback extends Backbone.View
  className: 'chat feedback'

  render: ->
    @$el.text @options.string
    @

class Views.Disconnected extends Backbone.View
  className: 'disconnected'

  events:
    'click button': -> document.location.reload()

  initialize: ->
    @$el.appendTo '#skylight'
    @render()

  render: ->
    @$el.html Templates[@className]()
    @

class Views.Options extends Backbone.View
  el: '#skylight .options'

  events:
    'click .hideOptions': 'hide'
    'change input': 'change'
    'change select': 'change'

  alerts:
    combat: 'Combat'
    rating: 'Rating'
    leg:    'Next Queue Leg'
    queue: 'Queue Completed'
    disconnect: 'Disconnect'
    chat: 'Chat'

  initialize: ->
    @render()

  render: ->
    vals = prefs.toJSON()
    _.extend vals, {MAX_RPTAG}
    vals.channels = ({name, active} for name, active of vals.channels)

    vals.alerts = for type, name of @alerts
      volume = prefs.get "#{type}Volume"
      popups = prefs.get "#{type}Popups"

      activeSound = prefs.get "#{type}Sound"
      sounds = for sound, soundName of SOUNDS
        {sound, soundName, active: sound is activeSound}

      activeDuration = prefs.get "#{type}PopupDuration"
      durations = for duration in POPUP_DURATIONS.concat(0)
        {duration, active: duration is activeDuration}

      {type, name, volume, popups, sounds, durations}

    @$el.html Templates.options vals
    @disable()
    @

  hide: ->
    @$el.removeClass 'show'

  show: ->
    @$el.addClass 'show'

  change: ->
    prefs.set 'rptag', $.trim(@$('.option.rptag input').val())
    prefs.set 'textarea', @$('.option.textarea input')[0].checked
    prefs.set 'volume', Number(@$('.option.volume input').val())
    prefs.set 'popups', @$('.option.popups input')[0].checked

    for alert of @alerts
      el = @$(".alert.#{alert}")
      prefs.set "#{alert}Volume", Number(el.find('.volume').val())
      prefs.set "#{alert}Popups", el.find('.popups')[0].checked
      prefs.set "#{alert}Sound", el.find('.sound').val()
      prefs.set "#{alert}PopupDuration", Number(el.find('.duration').val())

    channels = {}
    for channel of CHANNELS
      channels[channel] = @$(".channels input.#{channel}")[0].checked
    prefs.set 'channels', channels

    @disable()

  disable: ->
    mainSounds = !! prefs.get('volume')
    mainPopups = !! prefs.get('popups')

    for alert of @alerts
      el = @$(".alert.#{alert}")
      el.find('.volume').prop 'disabled', ! mainSounds
      sounds = mainSounds && !! prefs.get("#{alert}Volume")
      el.find('.sound').prop 'disabled', ! sounds
      el.find('.popups').prop 'disabled', ! mainPopups
      popups = mainPopups && !! prefs.get("#{alert}Popups")
      el.find('.duration').prop 'disabled', ! popups
      if alert is 'chat'
        @$(".channels input").prop 'disabled', ! sounds && ! popups

class Views.Window extends Backbone.View
  el: '#skylight .window'

  events:
    click: -> prefs.set 'active', false

  initialize: ->
    @render()

    for attr in ['combats', 'location']
      @[attr]()
      game.on "change:#{attr}", @[attr], @

    @combats()
    game.on "change:combats", @combats, @

    @location()
    game.queue.on "remove", @location, @

  render: ->
    @$el.html Templates.window()
    @

  combats: ->
    num = game.get 'combats'
    img = @$ '.combat'
    count = @$ '.combatCount'
    switch num
      when 0
        img.hide()
        count.hide()
      when 1
        img.show()
        count.hide()
      else
        img.show()
        count.show().html num

  location: ->
    location = game.get 'location'
    sky = @$('.sky')
    if location
      sky.removeClass 'flying'
      src = chrome.extension.getURL "island#{ISLAND_IMGS[location]}.png"
      title = ISLAND_NAMES[location]
      @$('.location img').attr {src, title}
    else
      src = chrome.extension.getURL "bg#{Math.floor(Math.random() * 10)}.jpg"
      @$('.background').attr {src}
      sky.toggleClass 'flyLeft', Math.random() < 0.005
      sky.addClass 'flying'
      src = chrome.extension.getURL "craft#{game.get 'craftId'}.png"
      title = game.get 'craftName'
      @$('.location img').attr {src, title}

class Views.Queue extends Backbone.View
  el: '#skylight .queue'

  initialize: ->
    game.queue.each (model) =>
      view = new Views.QueueEntry {model}
      @$el.append view.el
      model.view = view
    @render()
    @update()
    game.queue.on 'remove', @update, @

  render: ->
    game.queue.each (model) -> model.view.render()
    @

  update: ->
    game.queue.each (model) -> model.view.update()
    if (first = game.queue.first())
      remaining = first.get('endTime') - Date.now()
      MINUTE = 60000
      if remaining > MINUTE
        wait = remaining % MINUTE || MINUTE
        setTimeout =>
          @update()
        , wait

class Views.QueueEntry extends Backbone.View
  attributes: ->
    class: "entry #{@model.get 'type'}"

  initialize: ->
    @model.on 'change:complete', => @$el.addClass 'completed'
    @model.on 'change:market', @update, @

  render: ->
    context = _.extend @model.toJSON(), {craftId: game.get('craftId')}
    @$el.html Templates.queueEntry context
    @

  update: ->
    now = Date.now()
    {startTime, endTime} = @model.toJSON()
    [remaining, total] = if startTime > now
      [endTime - startTime, endTime - now]
    else
      [endTime - now, 0]
    @$('.remaining').html @formatTime remaining
    @$('.total').html @formatTime total

    classes = ['market']
    title = ""
    if (market = @model.get 'market')
      classes.push "m#{market}"
      title = MARKET[market]
    @$('.market').attr {title, class: classes.join(' ')}

  formatTime: (time) ->
    if time > 0
      minutes = Math.ceil(time / 60000)
      m = '' + minutes % 60
      m = '0' + m if m.length is 1
      h = Math.floor(minutes / 60)
      "#{h}:#{m}"
    else
      ''

class Views.News extends Backbone.View
  el: '#skylight .news'

  events:
    'click .forward': -> @setPos @pos + 1
    'click .forwardForward': -> @setPos @length - 1
    'click .back': -> @setPos @pos - 1
    'click .backBack': -> @setPos 0

  initialize: ->
    @render()
    @length = 0
    @itemWidth = @$('.inner').width()
    @items = @$ '.items'
    @collection = game.news
    @collection.each (item) => @add item
    @collection.on 'add', (item) => @add item

  render: ->
    @$el.html Templates.news()
    @

  setPos: (pos) ->
    return unless 0 <= pos <= @length - 1
    @pos = pos
    @update()
    @items.css left: - pos * @itemWidth

    # jquery's toggleClass doesn't work on svg elements
    disable = (selector, condition) =>
      $el = @$ selector
      klass = $el.attr 'class'
      klass = if condition
        klass += ' disabled' unless klass.match /\bdisabled\b/
      else
        klass.replace /\s?disabled/g, ''
      $el.attr class: klass

    disable '.forward', pos is @length - 1
    disable '.forwardForward', pos is @length - 1
    disable '.back', pos is 0
    disable '.backBack', pos is 0

  add: (model) ->
    model.view = new Views.NewsItem {model}
    @items.append model.view.render().el
    @length++
    @setPos(@length - 1) unless @pos? && @pos < @length - 2

  update: ->
    @collection.at(@pos).view.update()
    clearTimeout @updateTimeout
    @updateTimeout = setTimeout (=> @update()), 60000

class Views.NewsItem extends Backbone.View
  className: 'item'

  render: ->
    context = _.extend game.toJSON(), @model.toJSON()
    @$el.html Templates["news/#{context.type}"] context
    @

  update: ->
    ago = Date.now() - @model.get('time')
    minutes = Math.round ago / 60000
    str = if minutes > 0
      plural = (num) -> if num is 1 then '' else 's'
      hours = Math.floor minutes / 60
      time = if hours
        "#{hours} hour#{plural hours}"
      else
        "#{minutes} minute#{plural minutes}"
      time + ' ago'
    else
      'news just in'
    @$('.time').html str
