
escape = (text)->
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
  x = 100
  y = 100
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
    markup.push """<a #{attr params}>"""; more(); markup.push '</a>'

  ellipse = (params, more) ->
    elem 'ellipse', params, {fill:'#8e8', stroke:'#999', 'stroke-width':.5}, more

  rect = (params, more) ->
    elem 'rect', params, {}, more

  line = (params) ->
    elem 'line', params, {'stroke-width':6, stroke:'#ccc'}, ->

  text = (params, text) ->
    elem 'text', params, {'text-anchor':'middle'}, ->
      markup.push text.split(/ /)[0]

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
      link {'xlink:href': 'http://c2.com', 'data-node':node}, ->
        ellipse {cx:x, cy:y, rx:20, ry:20}, ->
          title node
        text {x,y}, node

  markup.join "\n"

emit = ($item, item) ->
  # $item.append "<pre>#{JSON.stringify place(parse(item.text)), null, '    '}</pre>"
  $item.append render place parse item.text

bind = ($item, item) ->
  $item.dblclick -> wiki.textEditor $item, item
  $item.find('a').click (e) ->
    e.preventDefault()
    node = $(e.target).parent('a').data('node')
    page = $item.parents '.page' unless e.shiftKey
    wiki.doInternalLink node, page

window.plugins.graph = {emit, bind} if window?
module.exports = {parse} if module?

