CIRCLE_SNAP_RADIUS = 8

main = ->
	# Indicates if path is being placed
	path_selection = false

	paper = Raphael $("#canvas")
	snapCircles = paper.set()

	createAnchor = (x, y) ->
		c = paper.circle x, y, 3
		c.attr
			fill: 'black'
			stroke: null

		snapCircle = paper.circle x, y, CIRCLE_SNAP_RADIUS
		snapCircle.attr
			'fill-opacity': 0.1
			fill: '#000'
			stroke: null

		snapCircle.data 'parent', c

		startPath = (ev, x, y) ->
			return if path_selection
			path_selection = true

			path = paper.path()
			path.attr { 'stroke': '#555', 'stroke-width': 2 }
			path.toBack()

			pointWithinAnyCircle = (circles, x, y) ->
				_.find circles, (circle) ->
					distance = Math.sqrt Math.pow(circle.attrs.cx - x, 2) + Math.pow(circle.attrs.cy - y, 2)
					return circle if distance <= CIRCLE_SNAP_RADIUS

			# Create a path and change attributes when mouse moves
			updatePath = (ev, mouseX, mouseY) =>
				otherCircles = _.without snapCircles, snapCircle
				snapTo = pointWithinAnyCircle otherCircles, mouseX, mouseY

				pathEnd = if snapTo
					"#{snapTo.attrs.cx} #{snapTo.attrs.cy}"
				else
					"#{mouseX} #{mouseY}"

				path.attr { path: "M#{this.attrs.cx} #{this.attrs.cy} L#{pathEnd}" }

			fixPath = (ev, mouseX, mouseY) =>
				# Initial click ends up here, ignore it
				return if snapCircle.isPointInside mouseX, mouseY

				otherCircles = _.without snapCircles, snapCircle
				snapTo = pointWithinAnyCircle otherCircles, mouseX, mouseY

				if snapTo
					# path.remove()
					# DO SOMETHING
				else
					path.remove()

				paper.raphael.unmousemove throttledUpdate
				paper.raphael.unclick fixPath
				path_selection = false

			throttledUpdate = _.throttle updatePath, 10

			paper.raphael.mousemove throttledUpdate
			paper.raphael.click fixPath

		snapCircle.click startPath
		snapCircle.hover ->
			c.attr { fill: 'red' }
		, ->
			c.attr { fill: '#000' }

		snapCircles.push snapCircle

	createLine = (x1, y1, x2, y2) ->
		line = new Object()
		line.points = [ [x1, y1], [x2, y2] ]

		path = paper.path()
		path.attr
			'stroke': '#555'
			'stroke-width': 2
			path: "M#{x1} #{y1} L#{x2} #{y2}"

		path.toBack()

		line.path = path
		line

	paperClick = (ev, x, y) ->
		return if path_selection
		createAnchor x, y

	paper.raphael.click paperClick

	createAnchor 50, 50
	createAnchor 50, 150
	createAnchor 200, 150
	# createAnchor 200, 50

	lines = []
	lines.push createLine 50, 50, 50, 150
	lines.push createLine 50, 50, 200, 150
	lines.push createLine 50, 150, 200, 150
	# lines.push createLine 50, 50, 200, 50
	# lines.push createLine 200, 50, 200, 150


	triangles = []

	traverseLine = (startLine) ->
		startLine.path.attr { stroke: 'red' }


	traverseLine lines[0]

	first = lines[0]
	first.path.attr
		stroke: 'red'
	
	otherLines = _.without lines, first

	pointEq = (p1, p2) ->
		p1.join() == p2.join()
	
	first.points.forEach (p) ->
		console.log "point: #{p}"
		otherPoint = _.without first.points, p
		console.log "otherPoint: #{otherPoint}"

		# Find lines that are connected to p
		connected = _.filter otherLines, (line) ->
			# See if any of the lines ends equal to p
			_.any line.points, (lp) -> _.isEqual p, lp

		console.dir "connected:"
		console.dir connected

		# connected.forEach (l) -> l.path.attr { stroke: 'green' }

		# Find lines that are connected to a line that is connected to otherPoint
		# TODO: foreach
		_.filter connected, (line) ->
			# TODO: connected should be all lines connected to line instaed
			# of lines connected to p			
			lns = _.without connected, line
			console.dir lns
			# lns.forEach (l) -> l.path.attr { stroke: 'blue' }

			_.filter lns, (l) ->
				# Remove point connected to first
				point = _.reject l.points, (pt) -> _.isEqual pt, p

				# Find lines that are connected to both otherPoint and point
				ok = _.find otherLines, (_l) ->
					_.all _l.points, (pp) -> pointEq(pp, otherPoint) or pointEq(pp, point)

				triangles.push [ first, l, ok ] if ok

		console.log ""
		console.log "NEXT"
		console.log ""

	console.log "triangles"
	console.dir triangles

	# Select lines that connect with either end of ´first´
	# l1 = _.filter _.without(lines, first), (line) ->
	#     _.any first.points, (point) ->
	#         _.any line.points, (lp) ->
	#             _.isEqual point, lp
	
	# l1.forEach (l) ->
	#     l.path.attr
	#         stroke: 'red'
	
$ -> main()
