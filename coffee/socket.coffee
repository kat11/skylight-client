class Socket
  _.extend @prototype, Backbone.Events

  host: 'skyrates.jusque.net'
  port: 8086
  pingRate: 3 * 60 * 1000

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

  pinger: ->
    if Date.now() - @pong > 2 * @pingRate
      @ws.close() unless @closed || @closing
    else
      @send 'ping'
      setTimeout (=> @pinger()), @pingRate
