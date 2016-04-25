
here = null

escape = (text)->
  return null unless text
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'

parse = (text) ->
  graph = {}
  children = (token) ->
    graph[token] || graph[token] = []

  last = from = direction = null
  for line in text.split(/\n/)
    tokens = line.trim().split(/\s*(-->|<--)\s*/)
    from = null
    for token in tokens
      if token == ''
        from = last
      else if token == '-->' or token == '<--'
        direction = token
      else
        if from?
          switch direction
            when '-->' then children(from).push token
            when '<--' then children(token).push from
        from = last = token
  graph

place = (graph) ->

  jiggle = ->
    Math.round((Math.random()-Math.random())*25)

  placed = {}
  x = y = 100
  for name, children of graph
    if not node = placed[name]
      placed[name] = node = [x+jiggle(), y+jiggle()]
      x += 100
    for child in children
      if not more = placed[child]
        placed[child] = more = [x-50+jiggle(), node[1]+75+jiggle()]
  {graph, placed}

render = ({graph, placed}) ->

  markup = []

  svg = (params, more) ->
    elem 'svg', params, {width:'420px', height:'320px'}, more

  link = (params, more) ->
    elem 'a', params, {}, more

  ellipse = (params, more) ->
    elem 'ellipse', params, {stroke:'#999', 'stroke-width':1}, more

  rect = (params, more) ->
    elem 'rect', params, {}, more

  line = (params) ->
    elem 'line', params, {'stroke-width':6, stroke:'#ccc'}, ->

  text = (params, text) ->
    elem 'text', params, {'text-anchor':'middle', dy:6}, ->
      markup.push text.split(' ')[0]

  elem = (tag, params, extra, more) ->
    markup.push "<#{tag} #{attr params} #{attr extra}>"; more(); markup.push "</#{tag}>"

  title = (text) ->
    markup.push "<title>#{text}</title>"

  attr = (params) ->
    ("#{k}=\"#{v}\"" for k, v of params).join " "

  svg {'viewBox':'0 0 420 320'}, ->
    rect {x: 0, y:0, width:420, height:320, fill:'#eee'}, ->

    for node, [x1, y1] of placed
      for child in graph[node]||[]
        [x2, y2] = placed[child] 
        line {x1, y1, x2, y2}

    for node, [x, y] of placed
      href = "http:/#{wiki.asSlug node}.html"
      {color, synopsis} = neighbor node
      link {'xlink:href':href, 'data-node':escape(node), 'data-synopsis':escape(synopsis)}, ->
        ellipse {cx:x, cy:y, rx:30, ry:20, fill:color}, ->
          title escape node
        text {x,y}, escape node

  markup.join "\n"

neighbor = (title) ->
  wanted = wiki.asSlug title
  return {color: '#ee8'} if title.toLowerCase() == here.toLowerCase()
  for site, query of wiki.neighborhood
    continue if query.sitemapRequestInflight or !query.sitemap
    for {slug, synopsis} in query.sitemap
      return {color: '#8ee', synopsis} if slug == wanted
  return {color: '#8e8'}


emit = ($item, item) ->
  here = $item.parents('.page').find('h1').text().trim()
  # $item.append "<pre>#{JSON.stringify place(parse(item.text)), null, '    '}</pre>"
  $item.append render place parse item.text
  $item.append """<p class="caption"></p>"""

  $item.addClass 'graph-source'
  $item.get(0).graphData = -> parse item.text

bind = ($item, item) ->
  $item.dblclick -> wiki.textEditor $item, item
  $item.find('a').click (e) ->
    e.preventDefault()
    node = $(e.target).parent('a').data('node')
    page = $item.parents '.page' unless e.shiftKey
    wiki.doInternalLink node, page
  $item.find('a').on 'hover', (e) ->
    console.log 'hover', html = $(e.target).parent('a').data('synopsis')
    $item.find('.caption').html(html)

window.plugins.graph = {emit, bind} if window?
module.exports = {parse} if module?

