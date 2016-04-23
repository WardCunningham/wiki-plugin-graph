
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
  $item.append """
    <div style="background-color: #eee; padding: 15px">
      <pre>#{JSON.stringify graph, null, '    '}</pre>
    </div>
  """


emit = ($item, item) ->
  render $item, parse item.text

bind = ($item, item) ->
  $item.dblclick -> wiki.textEditor $item, item

window.plugins.graph = {emit, bind} if window?
module.exports = {parse} if module?

