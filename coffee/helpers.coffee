Handlebars.registerHelper 'extension', (url..., options) ->
  chrome.extension.getURL url.join('')

Handlebars.registerHelper 'nonbreaking', (s) -> s.replace /\x20/g, '&nbsp;'

do ->
  fiesta = null
  styled = null

  URL_REGEX = ///
    (.*?)\b                                          # pre
    (https?://[^\s()]+ (?:
      \(\w+\) (?:[^\s())]* [^\s!'"(),.:;<=>?[\]])? |
      [^\s!'"(),.:;<=>?[\]]
    ))                                               # url
    (.*)                                             # post
  ///

  FIESTA_COLOURS = ['f44', '4f4', '77f', 'ff5', 'f5f', '5ff', 'f80']

  REPLACEMAYANTS = [
    [/([^-])--(?!-)/g, '$1—']
    [ /a`/g, 'á' ]
    [ /`a/g, 'à' ]
    [ /e`/g, 'é' ]
    [ /`e/g, 'è' ]
    [ /i`/g, 'í' ]
    [ /`i/g, 'ì' ]
    [ /o`/g, 'ó' ]
    [ /`o/g, 'ò' ]
    [ /u`/g, 'ú' ]
    [ /`u/g, 'ù' ]
    [ /<(3+)/g, (_,s) -> ('♥' for _ in s).join('') ]
  ]

  treatFiesta = (text) ->
    if fiesta
      text.replace /&[\w#]{1,10};|./g, (e) ->
        colour = Math.floor(Math.random() * FIESTA_COLOURS.length)
        colour = FIESTA_COLOURS[colour]
        "<span style=\"color:##{colour} !important;\">#{_.escape e}</span>"
    else
      _.escape text

  treatReplace = (text) ->
    for [from, to] in REPLACEMAYANTS
      text = text.replace from, to

    treatFiesta text

  treatLinks = (text) ->
    if (match = text.match URL_REGEX)
      [pre, url, post] = match[1..]
      treatReplace(pre) +
        "<a href=\"#{encodeURI url}\" target=\"_blank\">" +
        treatFiesta(url) +
        "</a>" +
        treatLinks(post)
    else
      treatReplace text

  treatItalic = (text) ->
    if (match = text.match /(.*?)\*(?=\S)([^*]*[^\s*])\*(.*)/)
      [pre, italic, post] = match[1..]
      treatLinks(pre) + "<i>#{treatLinks italic}</i>" + treatItalic(post)
    else
      treatLinks text

  treatBold = (text) ->
    if (match = text.match /(.*?)\*\*(?=\S)([^*]*[^\s*])\*\*(.*)/)
      [pre, bold, post] = match[1..]
      treatItalic(pre) + "<b>#{treatLinks bold}</b>" + treatBold(post)
    else
      treatItalic text

  # unless content =~ /^\/(b|i|ooc) /
  #   content.gsub! /(\*\*) (?=\S) ([^*]+) (?<=\S) \1/x, '<b>\2</b>'
  #   content.gsub! /(\*) (?=\S) (.+?) (?<=\S) \1/x, '<i>\2</i>'
  # end

  treat = (nodes) ->
    nodes = for node in nodes
      $node = $ node
      if node instanceof Text
        text = $node.text()
        if styled then treatLinks(text) else treatBold(text)
      else
        $node.html treat $node.contents()
        node.outerHTML
    nodes.join ''

  Handlebars.registerHelper 'chatContent', (content) ->
    fiesta = false
    if (match = content.match /^\/fiesta (.*)/)
      fiesta = true
      content = match[1]

    styled = !! content.match /<(i|b)>/

    content = content.replace /&(?!(lt|#60);)/g, '&amp;'

    treat $.parseHTML content

Handlebars.registerHelper 'popupChatContent', (content) ->
  content = content.replace /^\/fiesta\s+/, ''
  $('<div/>').html(content).text()

Handlebars.registerHelper 'itemName', (id) -> ITEMS[id]
Handlebars.registerHelper 'islandName', (id) -> ISLAND_NAMES[id]
Handlebars.registerHelper 'marketName', (id) -> MARKET[id].toLowerCase()

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

Handlebars.registerHelper 'upcase', (str) -> str.toUpperCase()

