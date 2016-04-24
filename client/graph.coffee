
escape = (text)->
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'

parse = (text) ->
  graph = {}
  last = from = null
  for line in text.split(/\n/)
    console.log line
    tokens = line.split(/\s*(-->|<--)\s*/)
    console.log 'tokens', tokens
    from = null
    for token in tokens
      console.log 'token', token, 'from', from
      if token == ''
        from = last
      else if token == '-->' or token == '<--'
        direction = token
      else
        if from?
          if direction == '-->'
            graph[from] = [token]
          else
            graph[token] = from
        from = last = token
  graph

place = (graph) ->
  placed = {}
  x = 100
  y = 100
  for name, children of graph
    console.log name
    if not node = placed[name]
      placed[name] = node = {name, x, y}
      x += 100
    for child in children
      if not more = placed[name]
        placed[child] = more = {name:child, x, y:child.y+50}
  nodes = (node for name, node of placed)
  # nodes = [{x:100, y:100}, {x:200, y:100}]
  edges = [{f:0, t:1}]
  {nodes, edges, graph}

render = ($item, {nodes, edges, graph}) ->
  $item.append """
    <div style="background-color: #eee; padding: 15px">
      <pre>#{JSON.stringify graph, null, '    '}</pre>
    </div>
  """

  markup = []

  svg = (params, more) ->
    markup.push """<svg width="420px" height="320px" viewBox="0 0 420 320" version="1.1" xmlns="http://www.w3.org/2000/markup" xmlns:xlink="http://www.w3.org/1999/xlink">"""
    more()
    markup.push '</svg>'

  link = (params, more) ->
    markup.push """<a xlink:#{attr params}>"""
    more()
    markup.push '</a>'

  ellipse = (params, more) ->
    markup.push """<ellipse #{attr params} fill="#8e8" stroke="#999" stroke-width=".5">"""
    more()
    markup.push '</ellipse>'

  rect = (params, more) ->
    markup.push "<rect #{attr params}>"
    more()
    markup.push '</rect>'

  text = (params, text) ->
    markup.push "<text #{attr params} text-anchor=\"middle\">"
    markup.push text.split(/ /)[0]
    markup.push '</text>'

  title = (text) ->
    markup.push "<title>#{text}</title>"

  jiggle = -> 
    (Math.random()-Math.random())*10

  attr = (params) ->
    ("#{k}=\"#{v}\"" for k, v of params).join " "

  svg {}, ->
    rect {x: 0, y:0, width:420, height:320, fill:'#eee'}, ->
    for node in nodes
      x = node.x + jiggle()
      y = node.y + jiggle()
      link {href: 'http://c2.com'}, ->
        ellipse {cx:x, cy:y, rx:20, ry:20}, ->
          title node.name
        text {x,y}, node.name

  $item.append markup.join "\n"

emit = ($item, item) ->
  render $item, place parse item.text

bind = ($item, item) ->
  # $item.dblclick -> wiki.textEditor $item, item

window.plugins.graph = {emit, bind} if window?
module.exports = {parse} if module?

