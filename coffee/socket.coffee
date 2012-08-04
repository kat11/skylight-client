# Socket communication with Skylight server.
#
# Socket class wraps a WebSocket connection in order to serialise / deserialise
# messages, and to allow the use of Backbone.Events to bind callbacks to
# specific message types.
#
# Triggered events:
#   'open' when the WebSocket opens
#   'closed' when the WebSocket closes
#   'broken' when the WebSocket closes and Socket#close has not been called
#   'message:message_type' when any of the various Skylight messages is
#     received. The message arguments are passed to bound callbacks.
#
# The various skylight messages aren't documented anywhere. Maybe one day.

class Socket
  _.extend @prototype, Backbone.Events

  host: 'skyrates.jusque.net'
  port: 8086

  # Send a 'ping' message this often. Close socket if we go twice this long
  # without receiving a pong.
  pingRate: 3 * 60 * 1000 # in milliseconds

  constructor: ->
    @url = "ws://#{@host}:#{@port}"
    @name = "Socket(#{@url})"
    @ws = new window.WebSocket @url
    @ws.onopen    = @onopen
    @ws.onclose   = @onclose
    @ws.onmessage = @onmessage

  onopen: =>
    # console.log "#{@name} open"
    @open = true
    @on 'message:pong', => @pong = Date.now()
    @pong = Date.now()
    @pinger()

    @trigger 'open'

  onclose: =>
    # console.log "#{@name} closed"
    @closed = true
    @trigger 'closed'
    @trigger 'broken' unless @closing

  # receive JSON array, trigger event called data[0], with remaining data
  # as args on the triggered event
  onmessage: (event) =>
    # console.log "#{@name} receive #{event.data}"
    data = JSON.parse event.data
    type = data.shift()
    @trigger "message:#{type}", data...

  close: ->
    return if @closed || @closing
    @closing = true
    @ws.close()

  # send args as JSON array
  send: (data...) ->
    return false if !@open || @closed || @closing
    # console.log "#{@name} send #{JSON.stringify data}"
    @ws.send JSON.stringify data
    true

  # periodically send pings, close unless we're being ponged
  pinger: ->
    if Date.now() - @pong > 2 * @pingRate
      @ws.close() unless @closed || @closing
    else
      @send 'ping'
      setTimeout (=> @pinger()), @pingRate
