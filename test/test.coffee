# build time tests for graph plugin
# see http://mochajs.org/

graph = require '../client/graph'
expect = require 'expect.js'

describe 'graph plugin', ->

  describe 'expand', ->

    it 'can make itallic', ->
      result = graph.expand 'hello *world*'
      expect(result).to.be 'hello <i>world</i>'
