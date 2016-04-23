
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
      else if token == '-->'
        direction = 'forward'
      else if token == '<--'
        direction = 'reverse'
      else
        if from?
          if direction == 'forward'
            graph[from] = [token]
          else
            graph[token] = from
        from = last = token
  graph

render = ($item, graph) ->
  # $item.append """
  #   <div style="background-color: #eee; padding: 15px">
  #     <pre>#{JSON.stringify graph, null, '    '}</pre>
  #   </div>
  # """
  svg = """
<svg width="5cm" height="3cm" viewBox="0 0 5 3" version="1.1"
     xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
  <desc>Example link01 - a link on an ellipse
  </desc>
  <rect x=".01" y=".01" width="4.98" height="2.98" 
        fill="none" stroke="blue"  stroke-width=".03"/>
  <a xlink:href="http://www.w3.org">
    <ellipse cx="2.5" cy="1.5" rx="2" ry="1"
             fill="red" />
  </a>
</svg>
  """
  $item.append svg

emit = ($item, item) ->
  render $item, parse item.text

bind = ($item, item) ->
  # $item.dblclick -> wiki.textEditor $item, item

window.plugins.graph = {emit, bind} if window?
module.exports = {parse} if module?

