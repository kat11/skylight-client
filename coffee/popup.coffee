document.addEventListener 'DOMContentLoaded', ->
  abandon = setTimeout (-> window.close()), 1000
  chrome.extension.sendMessage
    type: 'popupReady',
    id: window.location.search.slice(1)
  , (data) ->
    if data && data.content?
      document.body.className = data.type if data.type
      document.body.innerHTML = data.content
      setTimeout((-> window.close()), data.duration) if data.duration
      clearTimeout(abandon)
    else
      window.close()
