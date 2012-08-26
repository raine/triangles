_         = require 'underscore'
Benchmark = require 'benchmark'
fs        = require 'fs'

canvas = JSON.parse fs.readFileSync 'canvas.json'
mouse  = x: 80, y: 210

distance = (p1, p2) ->
	Math.sqrt Math.pow(p1.x - p2.x, 2) + Math.pow(p1.y - p2.y, 2)

method1 = ->
	_.find canvas.points, (p) ->
		distance(p, mouse) <= 10

method2 = ->
	_.find canvas.points, (p) ->
		if (p.x >= (mouse.x - 10) && p.x <= (mouse.x + 10)) && (p.y >= (mouse.y - 10) && p.y <= (mouse.y + 10))
			distance(p, mouse) <= 10

suite = new Benchmark.Suite

suite.add 'method 1', ->
	method1() for x in [1..100000]
suite.add 'method 2', ->
	method2() for x in [1..100000]

suite.on 'cycle', (event) ->
	console.log String(event.target)

suite.on 'complete', ->
	console.log 'Fastest is ' + this.filter('fastest').pluck('name')

suite.run { 'async': false }
