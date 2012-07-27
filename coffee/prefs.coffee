###
persistent preferences
###

class Prefs extends Backbone.Model
  key: 'skylight/prefs'

  defaults:
    active:   true
    rptag:    ""
    textarea: false
    channels: do -> o = {}; o[name] = true for name of CHANNELS; o
    volume: 1
    popups: true

    chatVolume: 1
    chatSound:  'typewriter'
    chatPopups: true
    chatPopupDuration: 6

    combatVolume: 1
    combatSound:  'airraid'
    combatPopups: false
    combatPopupDuration: 6

    disconnectVolume: 1
    disconnectSound:  'alarm'
    disconnectPopups: true
    disconnectPopupDuration: 0

    ratingVolume: 0
    ratingSound:  'alarm'
    ratingPopups: true
    ratingPopupDuration: 6

    legVolume: 0
    legSound:  'alarm'
    legPopups: true
    legPopupDuration: 6

    queueVolume: 1
    queueSound:  'alarm'
    queuePopups: true
    queuePopupDuration: 0

  constructor: ->
    attr = try
      @check JSON.parse localStorage.getItem @key
    catch e
      console.log e
      {}

    super attr

    @on 'change', =>
      localStorage.setItem @key, JSON.stringify(@)

  check: (attr) ->
    return {} unless _.isObject attr
    for prop, val of attr
      fn = 'check' + prop.replace /./, (c) -> c.toUpperCase()
      delete attr[prop] unless @[fn]?(val)
    attr

  checkActive: (v) -> _.isBoolean v

  checkRptag: (v) -> _.isString(v) && v.length <= MAX_RPTAG

  checkTextarea: (v) -> _.isBoolean v

  checkChannels: (v) ->
    _.isObject(v) &&
    _.all(CHANNELS, (id,k) => k of v) &&
    _.all(v, (active,k) -> k of CHANNELS && _.isBoolean(active))

  checkVolume: (v) -> _.isNumber(v) && 0 <= v <= 1

  checkPopups: (v) -> _.isBoolean v

  for alert in ['Chat', 'Combat', 'Disconnect', 'Rating', 'Leg', 'Queue']
    @::["check#{alert}Volume"] = (v) -> _.isNumber(v) && 0 <= v <= 1
    @::["check#{alert}Sound"] = (v) -> v of SOUNDS
    @::["check#{alert}Popups"] = (v) -> _.isBoolean v
    @::["check#{alert}PopupDuration"] = (v) ->
      _.isNumber(v) && (v is 0 || v in POPUP_DURATIONS)
