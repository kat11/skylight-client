timeouts = {}

clear = (id) -> chrome.notifications.clear id, -> null

chrome.notifications.onClosed.addListener (id) ->
  clearTimeout timeouts[id]
  delete timeouts[id]

chrome.notifications.onClicked.addListener (id) -> clear id

chrome.extension.onMessage.addListener (message, sender, respond) ->
  switch message.type

    # Content script wants a popup shown.
    # respond will be called with an popup id when it's displayed.
    when 'popup'
      opts =
        type: "basic",
        title: message.title,
        message: message.body,
        iconUrl: "#{message.img}.png"

      chrome.notifications.create "", opts, (id) ->
        timeouts[id] = setTimeout ->
          clear id
        , 1000
        respond id

      true # allows delayed response

    when 'popupDuration'
      {id, duration} = message
      return unless id of timeouts
      clearTimeout timeouts[id]
      switch duration
        when null
          clear id
        when 0
          null # stay
        else
          timeouts[id] = setTimeout ->
            clear id
          , duration
