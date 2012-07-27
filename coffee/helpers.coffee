Handlebars.registerHelper 'extension', (url..., options) ->
  chrome.extension.getURL url.join('')

Handlebars.registerHelper 'nonbreaking', (s) -> s.replace /\x20/g, '&nbsp;'

Handlebars.registerHelper 'chatContent', (content) ->
  fiesta = false

  # find and tag urls, do some html escaping, and fiestafy
  treat = (str) ->
    urlRegex = ///
      (.*?)\b                                                    # pre
      (https?://[^\s()<>]+(?:\([\w\d]+\)|[^\s!'"(),.:;<=>?[\]])) # url
      (.*)                                                       # post
    ///

    if (match = str.match urlRegex)
      [pre, url, post] = match[1..]
      treatChars(pre) +
      "<a href=\"#{url}\" target=\"_blank\">#{treatChars(url)}</a>" +
      treat(post)
    else
      treatChars str

  treatChars = (str) -> (treatChar(char) for char in str.split('')).join('')

  treatChar = (char) ->
    escapes =
      '<': '&lt;'
      '>': '&gt;'
      "'": '&#x27;'
      '"': '&quot;'
      '/': '&#x2F;'
      # '&': '&amp;'

    char = escapes[char] || char

    if fiesta and char != ' '
      colours = ['f44', '4f4', '66f', 'ff5', 'f5f', '5ff']
      colour  = colours[Math.floor(Math.random() * colours.length)]
      char    = "<span style=\"color:##{colour} !important;\">#{char}</span>"

    char

  do ->
    if (match = content.match /^\/fiesta (.*)/)
      fiesta = true
      content = match[1]

    tagRegex = /// ^
      ((?:<(?:i|b|font\s+color[^>]+)>)*) # opening tags
      (.*?)                              # body
      ((?:</(?:i|b|font)>)*)             # closing tags
    $ ///

    [open, content, close] = content.match(tagRegex)[1..]
    open + treat(content) + close

Handlebars.registerHelper 'itemName', (id) -> ITEMS[id]
Handlebars.registerHelper 'islandName', (id) -> ISLAND_NAMES[id]

Handlebars.registerHelper 'gt', (a, b, options) ->
  if a > b then options.fn(@) else options.inverse(@)

Handlebars.registerHelper 'eq', (a, b, options) ->
  if a is b then options.fn(@) else options.inverse(@)

Handlebars.registerHelper 'until', (time) ->
  plural = (num) -> if num is 1 then '' else 's'

  t = Math.max 0, time - Date.now()
  if t >= 50000
    hours = Math.floor t / 3600000
    minutes = Math.round t % 3600000 / 60000
    if minutes is 60
      minutes--
      hours++
    str = ''
    str += "#{hours} hour#{plural hours}" if hours
    str += ' and ' if hours and minutes
    str += "#{minutes} minute#{plural minutes}" if minutes
    str
  else
    seconds = Math.floor t / 1000
    "#{seconds} second#{plural seconds}"

Handlebars.registerHelper 'commaize', (num) ->
  str = ('' + num).split('').reverse().join('')
  str = str.replace /(\d{3}(?!-|$))/g, '$1,'
  str.split('').reverse().join('')

