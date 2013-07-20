popups = {}
popupId = 0

chrome.extension.onMessage.addListener (message, sender, respond) ->
  switch message.type

    # Content script wants a popup shown.
    # respond will be called with an popup id when it's displayed.
    when 'popup'
      id = popupId++
      popup = webkitNotifications.createNotification(
        chrome.extension.getURL("#{message.img}.png"),
        message.title,
        message.body
      )

      popups[id] = {popup}

      popup.onclose = ->
        delete popups[id]

      popup.ondisplay = ->
        popups[id].expire = setTimeout ->
          popup.cancel()
        , 1000
        respond id

      popup.onclick = ->
        popup.cancel()

      popup.show()
      true # allows delayed response

    when 'popupDuration'
      {id, duration} = message
      return unless popups[id]
      {popup, expire} = popups[id]
      clearTimeout expire
      switch duration
        when null
          popup.cancel()
        when 0
          null # stay
        else
          setTimeout ->
            popup.cancel()
          , duration
