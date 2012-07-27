popups = {}

# New id for a popup negotiation.
# Eventually recycle ids to prevent interrupted negotiations piling up.
popupId = do ->
  MAX_IDS = 10000
  prev = 0
  -> prev = (prev + 1) % MAX_IDS

chrome.extension.onMessage.addListener (message, sender, respond) ->
  switch message.type

    # Content script wants a popup shown.
    # respond will called with an popup id when one's ready.
    when 'popupRequest'
      id = popupId()
      popups[id] = {requestRespond: respond}
      webkitNotifications.createHTMLNotification("popup.html?#{id}").show()
      true # allows delayed response

    # The popup has popped up and is ready for its data.
    # message.id is the popup id that was sent as query parameter.
    # respond will be called with a data object.
    when 'popupReady'
      {id} = message
      popups[id].readyRespond = respond
      popups[id].requestRespond id
      true # allows delayed response

    # Content script has a data object for the ready popup.
    when 'popupContent'
      {id, data} = message
      popups[id].readyRespond data
      delete popups[id]










