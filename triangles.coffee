main = ->
	class Canvas
		constructor: (arg) ->
			@paper = Raphael arg
			Canvas.paper    = @paper
			Canvas.instance = this

			@points = []
			@path_mode = false

			@paper.raphael.click @click

		addPoint: (x, y) ->
			console.log "Adding a point to x: #{x}, y: #{y}"
			@points.push new Point x, y

		click: (event, x, y) =>
			@addPoint x, y unless @path_mode

		# Returns Point at x,y including the snap radius
		getPointsByPoint: (x, y) ->
			circle = _.first _.filter @paper.getElementsByPoint(x, y), (e) ->
				e.type is "circle"

			circle?.data 'point'

	class Point
		POINT_RADIUS: 3
		SNAP_RADIUS: 8

		constructor: (@x, @y) ->
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

			throttledUpdate = _.throttle updatePath, 10
			Canvas.paper.raphael.mousemove throttledUpdate


	canvas = new Canvas $("#canvas")
	canvas.addPoint 50,  50
	canvas.addPoint 100, 100

	# snapCircles = paper.set()
	# createAnchor = (x, y) ->
	#     startPath = (ev, x, y) ->
	#         return if path_selection
	#         path_selection = true

	#         path = paper.path()
	#         path.attr { 'stroke': '#555', 'stroke-width': 2 }
	#         path.toBack()

	#         pointWithinAnyCircle = (circles, x, y) ->
	#             _.find circles, (circle) ->
	#                 distance = Math.sqrt Math.pow(circle.attrs.cx - x, 2) + Math.pow(circle.attrs.cy - y, 2)
	#                 return circle if distance <= CIRCLE_SNAP_RADIUS

			# Create a path and change attributes when mouse moves
	#         updatePath = (ev, mouseX, mouseY) =>
	#             otherCircles = _.without snapCircles, snapCircle
	#             snapTo = pointWithinAnyCircle otherCircles, mouseX, mouseY

	#             pathEnd = if snapTo
	#                 "#{snapTo.attrs.cx} #{snapTo.attrs.cy}"
	#             else
	#                 "#{mouseX} #{mouseY}"

	#             path.attr { path: "M#{this.attrs.cx} #{this.attrs.cy} L#{pathEnd}" }

	#         fixPath = (ev, mouseX, mouseY) =>
				# Initial click ends up here, ignore it
	#             return if snapCircle.isPointInside mouseX, mouseY

	#             otherCircles = _.without snapCircles, snapCircle
	#             snapTo = pointWithinAnyCircle otherCircles, mouseX, mouseY

	#             if snapTo
					# path.remove()
					# DO SOMETHING
	#             else
	#                 path.remove()

	#             paper.raphael.unmousemove throttledUpdate
	#             paper.raphael.unclick fixPath
	#             path_selection = false

	#         throttledUpdate = _.throttle updatePath, 10

	#         paper.raphael.mousemove throttledUpdate
	#         paper.raphael.click fixPath

	#     snapCircle.click startPath
	#     snapCircle.hover ->
	#         c.attr { fill: 'red' }
	#     , ->
	#         c.attr { fill: '#000' }

	#     snapCircles.push snapCircle

	# createLine = (x1, y1, x2, y2) ->
	#     line = new Object()
	#     line.connectedTo = (point) ->
	#         _.any this.points, (p) -> _.isEqual(p, point)

	#     line.points = [ [x1, y1], [x2, y2] ]

	#     path = paper.path()
	#     path.attr
	#         'stroke': '#555'
	#         'stroke-width': 2
	#         path: "M#{x1} #{y1} L#{x2} #{y2}"

	#     path.toBack()

	#     line.path = path
	#     line

	# paperClick = (ev, x, y) ->
	#     return if path_selection
	#     createAnchor x, y

	# paper.raphael.click paperClick

$ -> main()
