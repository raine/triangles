# XXX: Canvas.instance could be saved into an instance variable

main = ->
	class Canvas
		constructor: (arg) ->
			@paper = Raphael arg
			Canvas.paper    = @paper
			Canvas.instance = this

			@points = []
			@lines  = []
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
				else
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

	canvas = new Canvas $("#canvas")
	canvas.addPoint 50,  50
	canvas.addPoint 100, 100
	canvas.addPoint 50,  150

	canvas.addLine 50, 50, 100, 100
	canvas.addLine 50, 50, 50, 150
	canvas.addLine 100, 100, 50, 150

$ -> main()
