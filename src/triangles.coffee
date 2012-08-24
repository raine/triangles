# XXX: Canvas.instance could be saved into an instance variable
# TODO: dragging but who cares really
# TODO: could continue in line mode after connecting
# TODO: triangle fills should probably be pushed to back when a line is added

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
		@pathMode  = false

		@paper.raphael.click @clickHandler
		@enableMousemove()
		@bindKeys()

	bindKeys: ->
		$(document).keyup (e) ->
			if e.keyCode is 27
				eve 'esc'

	mousemoveHandler: (event, x, y) =>
		if not @pathMode
			@snapMouseToLine x, y

	# Used when a circle is hovered
	disableMousemove: ->
		@paper.raphael.unmousemove @mousemoveHandler
		@removeSnapLine()

	enableMousemove: ->
		@paper.raphael.mousemove @mousemoveHandler

	snapMouseToLine: (x, y) ->
		for line, i in @lines
			if mousePoint = line.pointWithinRange x, y, 20
				_x = Math.round mousePoint.x
				_y = Math.round mousePoint.y

				if not @snapLineMode
					# Create a circle on the line in position nearest to mouse
					@snapLineC = Canvas.paper.circle _x, _y, Point::POINT_RADIUS
					@snapLineC.attr { fill: '#333', stroke: 'none' }
					# Ignore mouse events on the circle
					@snapLineC.node.style.pointerEvents = 'none'

				@snapLineC.attr { cx: _x, cy: _y }
				@snapLineMode = true
				break

			# Disable the mode if none of the lines match and it's enabled
			if @snapLineMode and i is @lines.length - 1
				@removeSnapLine()

	removeSnapLine: ->
		@snapLineC?.remove()
		@snapLineMode = false

	clickHandler: (event, x, y) =>
		if @snapLineMode
			{ cx, cy } = @snapLineC.attr()
			@addPoint cx, cy
			@removeSnapLine()
		else
			@addPoint x, y unless @pathMode

	addPoint: (x, y) ->
		@points.push (point = new Point x, y)
		console.log "Point added to canvas #{point}"

		line = @getLineByPoint point.x, point.y
		line.addPoint point if line

	addLine: (x1, y1, x2, y2) ->
		[ p1, p2 ] = _.filter @points, (p) ->
			(p.x is x1 and p.y is y1) or
				(p.x is x2 and p.y is y2)

		unless @getLineByPoints p1, p2
			@lines.push (line = new Line x1, y1, x2, y2)

			line.addPoint p1
			line.addPoint p2

			@checkTriangles p2
		else
			console.log 'Line exists bro'

	triangleExists: (points...) ->
		_.any @triangles, (t) ->
			_.difference(t.points, points).length is 0

	checkTriangles: (point) ->
		checked = []

		# Check every connected points connections and see which are
		# connected to ´point´
		point.connected().forEach (p) =>
			# Find the line that connects point and p
			connector = @getLineByPoints point, p

			# Ignore points that are in the same line that connects point and p
			# so that a single line with 3 points doesn't register as a triangle
			notChecked = _.difference _.without(p.connected(), checked...), connector.points

			# Find ´p´s connections (excluding the ones that are on the same
			# line as described above) that are connected to ´point´
			notChecked.forEach (_p) =>
				if _.include _p.connected(), point
					unless @triangleExists point, p, _p
						@triangles.push new Triangle point, p, _p
					else
						console.log 'Triangle exists'

			checked.push p

	getLineByPoints: (p1, p2) ->
		_.find @lines, (line) ->
			_.include(line.points, p1) and _.include(line.points, p2)

	# Returns Point at x,y including the snap radius
	getPointsByPoint: (x, y) ->
		# TODO: getElementsByPoint is bugged, can be solved with
		# pythagorean equation; problem is that it doesn't always detect
		# the elements
		circle = _.first _.filter @paper.getElementsByPoint(x, y), (e) ->
			e.type is 'circle'

		circle?.data 'point'

	getLineByPoint: (x, y) ->
		for line in @lines
			# http://stackoverflow.com/questions/6865832/detecting-if-a-point-is-of-a-line-segment
			# (Cy - Ay)  * (Bx - Ax) = (By - Ay) * (Cx - Ax).
			a = (y - line.start[1]) * (line.end[0] - line.start[0])
			b = (line.end[1] - line.start[1]) * (x - line.start[0])

			return line if Math.abs(a - b) <= 100

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

		@points = []

	addPoint: (point) ->
		@points.push point
		console.log "Line #{this} [#{@points.length}] - Point added #{point}"

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

	toString: ->
		"#{Canvas.instance.lines.indexOf(this) + 1}"

	highlight: ->
		oldColor = @path.attrs.stroke
		animate = (c, cb) =>
			@path.animate
				stroke: c
				500
				cb

		animate '#FF4D4D', ->
			setTimeout(
				-> animate(oldColor)
			, 2000)

class Point
	POINT_RADIUS: 3
	SNAP_RADIUS: 8

	constructor: (@x, @y) ->
		# @connected = []

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
			Canvas.instance.disableMousemove()
			@circle.attr { fill: 'red' }
		, =>
			Canvas.instance.enableMousemove()
			@circle.attr { fill: '#000' }

		@snap.click @startLine

	startLine: (ev, x, y) =>
		return if Canvas.instance.pathMode

		ev.cancelBubble = true
		Canvas.instance.pathMode = true

		path = Canvas.paper.path()
		path.attr { 'stroke': '#555', 'stroke-width': 2 }
		# path.toBack() TODO: with this the path will be behind triangle fills

		updatePath = (ev, mouseX, mouseY) =>
			point = Canvas.instance.getPointsByPoint mouseX, mouseY

			if point and point isnt this
				l = "#{point.x} #{point.y}"
			else
				l = "#{mouseX} #{mouseY}"

			path.attr { path: "M#{@x} #{@y} L#{l}" }

		cancel = ->
			path.remove()
			Canvas.paper.raphael.unclick fixPath
			Canvas.paper.raphael.unmousemove throttledUpdate
			Canvas.instance.pathMode = false

		fixPath = (ev, mouseX, mouseY) =>
			point = Canvas.instance.getPointsByPoint mouseX, mouseY

			if point and point isnt this
				Canvas.instance.addLine @x, @y, point.x, point.y

			cancel()

		eve.once "esc", cancel

		throttledUpdate = _.throttle updatePath, 10
		Canvas.paper.raphael.mousemove throttledUpdate
		Canvas.paper.raphael.click fixPath

	connected: ->
		# XXX: Point could keep track of lines
		lines = _.filter Canvas.instance.lines, (line) =>
			_.include line.points, this

		_.without(_.flatten(_.pluck(lines, 'points')), this)

	# Connect point to a line if it's on any
	foobar: ->
		line = Canvas.instance.getLineByPoint @x, @y
		line.addPoint this if line

	connect: (point) ->
		console.log "Point #{this} connected to #{point}"
		@connected.push point

	color: (str) ->
		@circle.attr { fill: str }

	toString: ->
		"(#{@x}, #{@y})"
