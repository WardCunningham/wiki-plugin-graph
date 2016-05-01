# build time tests for graph plugin
# see http://mochajs.org/

graph = require '../client/graph'
expect = require 'expect.js'

describe 'graph plugin', ->
  eg = (input, output) ->
    result = graph.parse 'Earth', input
    expect(result).to.eql output


  describe 'nodes', ->

    it 'can be one word', ->
      eg 'Earth', {Earth:[]}

    it 'can be word HERE', ->
      eg 'HERE', {Earth:[]}

    it 'can be many words', ->
      eg 'Earth and Moon', {'Earth and Moon':[]}

    it 'can include punctuation', ->
      eg 'Earth < Sun', {'Earth < Sun':[]}

    it 'will ignore surounding whitespace', ->
      eg '\tEarth and Moon   ', {'Earth and Moon':[]}

    it 'will end at a newline', ->
      eg 'Earth\nBeyond', {Earth:[], Beyond:[]}

  describe 'arcs', ->

    it 'can go forward', ->
      eg "HERE --> Moon", {Earth:['Moon'], Moon:[]}

    it 'can go backwards', ->
      eg "HERE <-- Moon", {Moon:['Earth'], Earth:[]}

    it 'can go both ways', ->
      eg "Earth <-> Moon", {Moon:['Earth'], Earth:['Moon']}

    it 'can chain forward', ->
      eg "Earth --> Moon --> Mars", {Earth:['Moon'], Moon:['Mars'], Mars:[]}

    it 'can chain backwards', ->
      eg "Earth <-- Moon <-- Mars", {Earth:[], Moon:['Earth'], Mars:['Moon']}

    it 'can converge', ->
      eg "Earth --> Moon <-- Mars", {Earth:['Moon'], Mars:['Moon'], Moon:[]}

    it 'can diverge', ->
      eg "Earth <-- Moon --> Mars", {Moon:['Earth', 'Mars'], Earth:[], Mars:[]}

  describe 'arcs continue', ->

    it 'from above', ->
      eg "Earth --> Moon\n--> Mars", {Earth:['Moon'], Moon:['Mars'], Mars:[]}

    it 'to below', ->
      eg "Earth -->\nMoon --> Mars", {Earth:['Moon'], Moon:['Mars'], Mars:[]}

    it 'above and below', ->
      eg "Earth -->\nMoon\n--> Mars", {Earth:['Moon'], Moon:['Mars'], Mars:[]}

    it 'all alone', ->
      eg "Earth\n-->\nMoon\n-->\nMars", {Earth:['Moon'], Moon:['Mars'], Mars:[]}

  describe 'redundant', ->

    it 'nodes merge', ->
      eg "Earth\nEarth", {Earth:[]}

    it 'arcs merge', ->
      eg "Earth --> Moon\nEarth --> Moon", {Earth: ['Moon'], Moon:[]}

