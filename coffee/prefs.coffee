###
Preference settings stored persistently in localStorage.

Backbone.Model is leveraged for its getters and setters and whatnot, but
Backbone.Sync is not used. Instead the model is written as JSON to localStorage
whenever the change event is triggered, and read once from localStorage at
instantiation.

To add a new attribute:
  1. set a default value for the attribute under defaults as:
     attributeName: value
  2. add a checkAttributeName function that checks that the value read from
     storage is a valid value for the attribute. The function receives the
     stored value as argumentand should return true if the value is valid,
     otherwise the stored value will be discarded and the default value used.
###

class Prefs extends Backbone.Model
  key: 'skylight/prefs' # the key under which the JSON lives in localStorage

  defaults:
    # true if using skylight rather that flashy skyrates
    active:   true

    # tag injected as start of messages to roleplay channel
    rptag:    ""

    # true if using big textarea instead of little textfield for chatting
    textarea: false

    # the channels selected for chat alerts
    channels: do -> o = {}; o[name] = true for name of CHANNELS; o

    # master volume for sounds
    volume: 1

    # master switch for whether to show popups
    popups: true

    # alert settings
    # popupDuration is in seconds, 0 for sticky popups

    # settings for alerts on chat message received
    chatVolume: 1
    chatSound:  'typewriter'
    chatPopups: true
    chatPopupDuration: 6

    # settings for alerts on new combat available
    combatVolume: 1
    combatSound:  'airraid'
    combatPopups: false
    combatPopupDuration: 6

    # settings for alerts on socket disconnect
    disconnectVolume: 1
    disconnectSound:  'alarm'
    disconnectPopups: true
    disconnectPopupDuration: 0

    # settings for alerts on rating received
    ratingVolume: 0
    ratingSound:  'alarm'
    ratingPopups: true
    ratingPopupDuration: 6

    # settings for alerts on start of queue leg
    legVolume: 0
    legSound:  'alarm'
    legPopups: true
    legPopupDuration: 6

    # settings for alerts on end of queue
    queueVolume: 1
    queueSound:  'alarm'
    queuePopups: true
    queuePopupDuration: 0

  constructor: ->
    attr = try
      # get values out of storage and validate them
      @check JSON.parse localStorage.getItem @key
    catch e
      console.log e
      {}

    # Instantiate model with valid attributes. Missing attributes are filled in
    # from defaults.
    super attr

    # dump entire model to strorage if anything changes
    @on 'change', =>
      localStorage.setItem @key, JSON.stringify(@)

  # pass the stored attributes to corresponding check functions. Delete the
  # stored value unless the check returns truthy.
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
