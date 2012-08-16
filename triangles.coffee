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

	createPath = (x1, y1, x2, y2) ->
		path = paper.path()
		path.attr
			'stroke': '#555'
			'stroke-width': 2
			path: "M#{x1} #{y1} L#{x2} #{y2}"

		path.toBack()

	paperClick = (ev, x, y) ->
		return if path_selection
		createAnchor x, y

	paper.raphael.click paperClick

	createAnchor 50, 50
	createAnchor 200, 50
	createAnchor 50, 150
	createAnchor 200, 150

	createPath 50, 50, 200, 50
	createPath 50, 50, 50, 150
	createPath 50, 50, 200, 150
	createPath 50, 150, 200, 150
	createPath 200, 50, 200, 150

$ -> main()
