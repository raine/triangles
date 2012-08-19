# XXX: Canvas.instance could be saved into an instance variable
# TODO: dragging but who cares really
# TODO: rainbow colors

# COLORS = [ '#D1F2A5', '#EFFAB4', '#FFC48C', '#FF9F80', '#F56991' ]
COLORS = [ '#FF4D4D', '#FF9D4D', '#FFF64D', '#8EFF4D', '#4DDBFF' ]

class Rotate
	constructor: (@arr) ->
		@i = 0

	next: ->
		@i = 0 if @i is @arr.length
		@arr[@i++]

# COLORS = [ 'blue', 'lime', 'fuchsia', 'yellow', 'red', 'purple', 'maroon', 'aqua', 'navy', 'teal', 'olive', 'green' ]

main = ->
	class Canvas
		constructor: (arg) ->
			@paper  = Raphael arg
			@colors = new Rotate COLORS
			Canvas.paper    = @paper
			Canvas.instance = this

			@points    = []
			@lines     = []
			@triangles = []
			@path_mode = false

			@paper.raphael.click @click

		addPoint: (x, y) ->
			console.log "Point added – x: #{x}, y: #{y}"
			@points.push new Point x, y

		addLine: (x1, y1, x2, y2) ->
			@lines.push new Line x1, y1, x2, y2
			@checkConnections arguments...

		checkConnections: (x1, y1, x2, y2) ->
			points = _.filter @points, (p) ->
				(p.x is x1 and p.y is y1) or
				(p.x is x2 and p.y is y2)

			points[0].connect points[1]
			points[1].connect points[0]

			@checkTriangles points[1]

		triangleExists: (points...) ->
			_.any @triangles, (t) ->
				_.difference(t.points, points).length is 0

		checkTriangles: (point) ->
			checked = []

			# Check every connected points connections and see which are
			# connected to ´point´
			point.connected.forEach (p) =>
				# ´p´s connections that are connected to ´point´
				notChecked = _.without p.connected, checked...
				notChecked.forEach (_p) =>
					if _.include _p.connected, point
						unless @triangleExists point, p, _p
							@triangles.push new Triangle point, p, _p
						else
							console.log 'Triangle exists'

				checked.push p

		click: (event, x, y) =>
			@addPoint x, y unless @path_mode

		# Returns Point at x,y including the snap radius
		getPointsByPoint: (x, y) ->
			# TODO: getElementsByPoint is bugged, can be solved with
			# pythagorean equation; problem is that it doesn't always detect
			# the elements
			circle = _.first _.filter @paper.getElementsByPoint(x, y), (e) ->
				e.type is "circle"

			circle?.data 'point'

	class Triangle
		constructor: (@points...) ->
			console.log 'New triangle'
			@fill()

		fill: ->
			[ p1, p2, p3 ] = @points

			pathStr = "M#{p1.x} #{p1.y} L#{p2.x} #{p2.y} L#{p3.x} #{p3.y} Z"
			path = Canvas.paper.path pathStr
			path.attr
				fill : Canvas.instance.colors.next()
				'fill-opacity': 0.5
				stroke: 'none'
			path.toBack()

	class Line
		constructor: (obj) ->
			# obsolete
			if obj.type is 'path'
				@path  = obj
				@start = @path.attrs.path[0].slice(1, 3)
				@end   = @path.attrs.path[1].slice(1, 3)

			else if arguments.length is 4 # x1, y1, x2, y2
				args = Array::slice.call arguments
				@start = args.slice 0, 2
				@end   = args.slice 2, 4

				@path = Canvas.paper.path()
				@path.attr
					'stroke': '#555'
					'stroke-width': 2
					path: "M#{@start.join ','} L#{@end.join ','}"

				@path.toBack()

			console.log "Line added from #{@start} to #{@end}"

	class Point
		POINT_RADIUS: 3
		SNAP_RADIUS: 8

		constructor: (@x, @y) ->
			@connected = []

			@circle = Canvas.paper.circle x, y, Point::POINT_RADIUS
			@circle.attr
				fill: 'black'
				stroke: 'none'

			@snap = Canvas.paper.circle x, y, Point::SNAP_RADIUS
			@snap.attr
				'fill-opacity': 0.1
				fill: '#000'
				stroke: 'none'

			@circle.data 'point', this
			@snap.data 'point', this

			@snap.hover =>
				@circle.attr { fill: 'red' }
			, =>
				@circle.attr { fill: '#000' }

			@snap.click @startLine

		startLine: (ev, x, y) =>
			return if Canvas.instance.path_mode

			ev.cancelBubble = true
			Canvas.instance.path_mode = true

			path = Canvas.paper.path()
			path.attr { 'stroke': '#555', 'stroke-width': 2 }
			path.toBack()

			updatePath = (ev, mouseX, mouseY) =>
				point = Canvas.instance.getPointsByPoint mouseX, mouseY

				if point and point isnt this
					l = "#{point.x} #{point.y}"
				else
					l = "#{mouseX} #{mouseY}"

				path.attr { path: "M#{@x} #{@y} L#{l}" }

			fixPath = (ev, mouseX, mouseY) =>
				point = Canvas.instance.getPointsByPoint mouseX, mouseY

				if point and point isnt this
					Canvas.instance.addLine @x, @y, point.x, point.y

				path.remove()

				Canvas.paper.raphael.unclick fixPath
				Canvas.paper.raphael.unmousemove throttledUpdate
				Canvas.instance.path_mode = false

			throttledUpdate = _.throttle updatePath, 10
			Canvas.paper.raphael.mousemove throttledUpdate
			Canvas.paper.raphael.click fixPath

		toString: ->
			[ @x, @y ].join ','

		connect: (point) ->
			console.log "Point #{this} connected to #{point}"
			@connected.push point

		color: (str) ->
			@circle.attr { fill: str }

	canvas = new Canvas $("#canvas")

	canvas.addPoint 50,  50
	canvas.addPoint 100, 100
	canvas.addPoint 50,  150
	canvas.addPoint 100,  50

	canvas.addLine 50, 50, 100, 100
	canvas.addLine 50, 50, 50, 150
	canvas.addLine 100, 100, 50, 150

	canvas.addLine 50, 50, 100, 50
	canvas.addLine 100, 50, 100, 100

	canvas.checkTriangles canvas.points[0]

$ -> main()
