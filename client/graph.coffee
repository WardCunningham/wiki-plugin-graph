bound = false

escape = (text)->
  return null unless text
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'

parse = (here, text) ->
  merge = (arcs, right) ->
    arcs.push right if arcs.indexOf(right) == -1
  graph = {}
  left = op = right = null
  for line in text.split(/\n/)
    tokens = line.trim().split(/\s*(-->|<--|<->)\s*/)
    for token in tokens
      if token == ''
      else if token == '-->' or token == '<--' or token == '<->'
        op = token
      else
        right = if token == 'HERE' then here else token
        graph[right] ||= []
        if left? && op? && right?
          switch op
            when '-->' then merge graph[left], right
            when '<--' then merge graph[right], left
            when '<->' then merge graph[left], right; merge graph[right], left
        left = right
        op = right = null
  graph

place = (graph) ->

  height = 0

  copy = (loc) ->
    [loc[0], loc[1]]

  looping = (node) ->
    for child in graph[node]
      for grand in graph[child]
        return true if node == grand and placed[child]?
        for great in graph[grand]
          return true if node == great and placed[grand]? and placed[child]?
    false

  placed = {}
  origin = [50, 50]
  for name, children of graph
    if not placed[name]
      placed[name] = copy origin
      origin[0] += 100
    node = copy placed[name]
    node[1] += 75
    height = Math.max height, node[1]
    for child in children
      if not placed[child]
        node[0] += 50 if looping(child)
        placed[child] = copy node
        node[0] += 75
  {graph, placed, height:height-20}

render = ({graph, placed, height}) ->
  console.log {graph, placed, height}

  markup = []

  svg = (params, more) ->
    elem 'svg', params, {width:'420px', height:"#{height}px"}, more

  link = (params, more) ->
    elem 'a', params, {}, more

  ellipse = (params, more) ->
    elem 'ellipse', params, {stroke:'#999', 'stroke-width':1}, more

  rect = (params, more) ->
    elem 'rect', params, {}, more

  line = (params) ->
    elem 'line', params, {'stroke-width':6, stroke:'#ccc'}, ->

  path = ({x1, y1, x2, y2}) ->
    qx = (x1+x2)/2 + Math.abs(y2-y1)/2
    qy = (y1+y2)/2
    d = "M#{x1} #{y1} Q#{qx} #{qy} #{x2} #{y2}"
    elem 'path', {d}, {'stroke-width':6, stroke:'#ccc', fill:'transparent'}, ->

  text = (params, text) ->
    elem 'text', params, {'text-anchor':'middle', dy:6}, ->
      markup.push text.split(' ')[0]

  elem = (tag, params, extra, more) ->
    markup.push "<#{tag} #{attr params} #{attr extra}>"; more(); markup.push "</#{tag}>"

  title = (text) ->
    markup.push "<title>#{text}</title>"

  attr = (params) ->
    ("#{k}=\"#{v}\"" for k, v of params).join " "

  svg {'viewBox':"0 0 420 #{height}"}, ->
    rect {x: 0, y:0, width:420, height, fill:'#eee'}, ->

    for node, [x1, y1] of placed
      for child in graph[node]||[]
        [x2, y2] = placed[child]
        if y2 >= y1
          line {x1, y1, x2, y2}
        else
          path {x1, y1, x2, y2}

    for node, [x, y] of placed
      href = "http:/#{wiki.asSlug node}.html"
      link {'xlink:href':href, 'data-node':escape(node)}, ->
        ellipse {cx:x, cy:y, rx:30, ry:20, fill:'#fff'}, ->
          title escape node
        text {x,y}, escape node

  markup.join "\n"

neighbor = (here, title) ->
  wanted = wiki.asSlug title
  return {color: '#ee8'} if title.toLowerCase() == here.toLowerCase()
  for site, query of wiki.neighborhood
    continue if query.sitemapRequestInflight or !query.sitemap
    for {slug, synopsis} in query.sitemap
      return {color: '#8ee', synopsis} if slug == wanted
  return {color: '#8e8'}

colorcode = (here, $item) ->
  $item.find('a').each (i, a) ->
    $a = $(a)
    title = $a.data('node')
    {color, synopsis} = neighbor here, title
    $a.data('synopsis', synopsis) if synopsis
    $a.find('ellipse').attr('fill', color)

emit = ($item, item) ->

  here = $item.parents('.page').find('h1').text().trim()
  $item.append render place parse here, item.text
  $item.append """<p class="caption"></p>"""

  $item.addClass 'graph-source'
  $item.get(0).graphData = -> parse here, item.text

bind = ($item, item) ->

  here = $item.parents('.page').find('h1').text().trim()

  $item.dblclick -> wiki.textEditor $item, item

  unless bound
    bound = true
    $('body').on 'new-neighbor-done', (e, neighbor) ->
      $('.page').each (i, p) ->
        $page = $(p)
        here = $page.find('h1').text().trim()
        $page.find('.item.graph').each (j, g) ->
          $item = $(g)
          colorcode here, $item

  $item.on 'drop', (e) ->
    e.preventDefault()
    e.stopPropagation()
    url = e.originalEvent.dataTransfer.getData("URL")
    return unless url
    segs = url.split '/'
    return unless (n = segs.length) >= 5
    site = if segs[n-2] == 'view' then segs[2] else segs[n-2]
    slug = segs[n-1]
    wiki.pageHandler.get
      pageInformation: {site, slug}
      whenNotGotten: -> console.error "Graph drop: Can't parse '#{url}'"
      whenGotten: (pageObject) ->
        title = pageObject.getTitle()
        h = $('.page').index($item.parents('.page'))
        t = $('.page').index($(".page##{slug}"))
        item.text = if t < h
          "#{title} --> HERE\n" + item.text
        else
          item.text + "\nHERE --> #{title}"
        update(site)

  rebind = ->
    colorcode here, $item

    $item.find('a').click (e) ->
      e.preventDefault()
      e.stopPropagation()
      node = $(e.target).parent('a').data('node')
      page = $item.parents '.page' unless e.shiftKey
      wiki.doInternalLink node, page

    $item.find('a').on 'hover', (e) ->
      anchor = $(e.target).parent('a')
      synopsis = anchor.data('synopsis') || ''
      html = "<b>#{anchor.data 'node'}</b><br>#{wiki.resolveLinks synopsis}"
      $item.find('.caption').html(html)

  rebind()


  update = (site) ->
    $item.empty()
    emit($item, item)
    rebind()
    action =
      type: 'edit',
      id: item.id,
      item: item
    if site != location.host
      action.site = site
    wiki.pageHandler.put $item.parents('.page:first'),action


window.plugins.graph = {emit, bind} if window?
module.exports = {parse} if module?

