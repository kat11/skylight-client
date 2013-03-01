# Script used in the popups. The popups initially pop up with no content, then
# send a message to the background script asking for the content the popup was
# created to show.

document.addEventListener 'DOMContentLoaded', ->
  hover = false
  expired = false

  expire = ->
    expired = true
    window.close() unless hover

  document.onmouseover = -> hover = true
  document.onmouseout = (evt) ->
    return if evt.toElement
    hover = false
    window.close() if expired

  # give up and close the popup if it's taking too long to negotiate content.
  abandon = setTimeout (-> window.close()), 1000

  # id for this popup was sent as a query parameter
  chrome.extension.sendMessage
    type: 'popupReady',
    id: window.location.search.slice(1)

  , (data) ->
    # data should be an object with properties:
    #   content: html string
    #   type: class to be set on body
    #   duration: milliseconds lifetime if the popup should automatically close
    if data && data.content?
      document.body.className = data.type if data.type
      document.body.innerHTML = data.content
      setTimeout(expire, data.duration) if data.duration
      clearTimeout(abandon)
    else
      window.close()
