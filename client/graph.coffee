
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
  placed = {}
  x = 100
  y = 100
  for name, children of graph
    if not node = placed[name]
      placed[name] = node = {name, x, y}
      x += 100
    for child in children
      if not more = placed[name]
        placed[child] = more = {name:child, x, y:child.y+50}
  nodes = (node for name, node of placed)
  edges = [{f:0, t:1}]
  {nodes, edges, graph}

render = ({nodes, edges, graph}) ->

  markup = []

  svg = (params, more) ->
    elem 'svg', params, {width:'420px', height:'320px'}, more

  link = (params, more) ->
    markup.push """<a #{attr params}>"""; more(); markup.push '</a>'

  ellipse = (params, more) ->
    elem 'ellipse', params, {fill:'#8e8', stroke:'#999', 'stroke-width':.5}, more

  rect = (params, more) ->
    elem 'rect', params, {}, more

  text = (params, text) ->
    elem 'text', params, {'text-anchor':'middle'}, ->
      markup.push text.split(/ /)[0]

  elem = (tag, params, extra, more) ->
    markup.push "<#{tag} #{attr params} #{attr extra}>"; more(); markup.push "</#{tag}>"

  title = (text) ->
    markup.push "<title>#{text}</title>"

  jiggle = -> 
    (Math.random()-Math.random())*10

  attr = (params) ->
    ("#{k}=\"#{v}\"" for k, v of params).join " "

  svg {'viewBox':'0 0 420 320'}, ->
    rect {x: 0, y:0, width:420, height:320, fill:'#eee'}, ->
    for node in nodes
      x = node.x + jiggle()
      y = node.y + jiggle()
      link {'xlink:href': 'http://c2.com'}, ->
        ellipse {cx:x, cy:y, rx:20, ry:20}, ->
          title node.name
        text {x,y}, node.name

  markup.join "\n"

emit = ($item, item) ->
  $item.append render place parse item.text
  $item.append "<pre>#{JSON.stringify place(parse(item.text)), null, '    '}</pre>"

bind = ($item, item) ->
  $item.dblclick -> wiki.textEditor $item, item

window.plugins.graph = {emit, bind} if window?
module.exports = {parse} if module?

