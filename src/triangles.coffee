# XXX: Canvas.instance could be saved into an instance variable
# TODO: dragging but who cares really
# TODO: ability to add points in middle of a line
# TODO: don't show line snap circle when placing a line
# TODO: don't show line snap circle when hovering a point

COLORS = _.shuffle [ '#FF4D4D', '#FF9D4D', '#FFF64D', '#8EFF4D', '#4DDBFF' ]

class Canvas
	constructor: (arg) ->
		@paper  = Raphael arg
		@colors = new Rotate COLORS
		Canvas.paper    = @paper
		Canvas.instance = this

		@points    = []
		@lines     = []
		@triangles = []
		@pathMode = false

		@paper.raphael.click @clickHandler
		@paper.raphael.mousemove @mousemoveHandler

	mousemoveHandler: (event, x, y) =>
		@snapMouseToLine x, y

	snapMouseToLine: (x, y) ->
		for line, i in @lines
			if mousePoint = line.pointWithinRange x, y, 20
				_x = Math.round mousePoint.x
				_y = Math.round mousePoint.y

				if not @snapLineMode
					# Create a circle on the line in position nearest to mouse
					@snapLineC = Canvas.paper.circle _x, _y, Point::POINT_RADIUS
					@snapLineC.attr { fill: '#333', stroke: 'none' }

				@snapLineC.attr { cx: _x, cy: _y }
				@snapLineMode = true
				break

			# Disable the mode if none of the lines match and it's enabled
			if @snapLineMode and i is @lines.length - 1
				@disableSnapLine()

	disableSnapLine: ->
		@snapLineC?.remove()
		@snapLineMode = false

	clickHandler: (event, x, y) =>
		if @snapLineMode
			{ cx, cy } = @snapLineC.attr()
			@addPoint cx, cy
			@disableSnapLine()
		else
			@addPoint x, y unless @pathMode

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

	# See if (x, y) is within range of the line
	# Returns Raphael point object of mouse coordinates on the line
	pointWithinRange: (x, y, range) ->
		# @start, @end and (x, y) form a triangle
		# Below are the sides of the triangle
		base = @path.getTotalLength()
		d1   = Utils.distance @start[0], @start[1], x, y
		d2   = Utils.distance @end[0], @end[1], x, y

		# If base is the longest side, (x, y) is "between" @start and @end
		if base > d1 and base > d2
			p    = (base + d1 + d2) / 2                           # Semiperimeter of the triangle
			area = Math.sqrt p * (p - d1) * (p - d2) * (p - base) # Area of the triangle
			h    = (2 * area) / base                              # Altitude of the triangle from base

			if h <= 10
				s = d1 / Math.sin Math.PI/2   # Law of Sines ratio
				a = Math.asin h / s           # Angle of the corner at @start
				b = Math.PI - (Math.PI/2 + a) # Angle of the corner at (x, y)

				# Distance from @start to position of mouse on the line
				l = Math.sqrt Math.pow(d1, 2) + Math.pow(h, 2) - (2 * d1 * h * Math.cos(b))
				# Coordinates of mouse on the line
				@path.getPointAtLength l
			else
				false

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
		return if Canvas.instance.pathMode

		ev.cancelBubble = true
		Canvas.instance.pathMode = true

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
			Canvas.instance.pathMode = false

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
