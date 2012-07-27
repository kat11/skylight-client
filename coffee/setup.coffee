# global vars
prefs   = new Prefs # persistent preferences
socket  = null      # Socket instance to talk with skylight server
alerter = null      # fire sounds and popups
game    = null      # character and game state

if prefs.get('active')
  # block load of flash client
  document.addEventListener "beforeload", (event) ->
    if event.url.match /bin\/loader.swf|images\/need-flash-9.jpg/
      event.preventDefault()
  , true

  socket  = new Socket
  game    = new Models.Game
  alerter = new Alerter

# document ready
$ ->
  if $('#client').length
    new Views.Switcher
    new Views.Skylight if prefs.get('active')
