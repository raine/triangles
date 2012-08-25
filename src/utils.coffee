class Rotate
	constructor: (@arr) ->
		@i = 0

	next: ->
		@i = 0 if @i is @arr.length
		@arr[@i++]

Utils = (->
	distance: (x1, y1, x2, y2) ->
		Math.sqrt Math.pow(x1 - x2, 2) + Math.pow(y1 - y2, 2)

	exportCanvas: ->
		obj = points: []

		Canvas.instance.points.forEach (p) ->
			obj.points.push
				x: p.x
				y: p.y

		console.log JSON.stringify obj
)()
