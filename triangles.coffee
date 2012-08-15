main = ->
	paper   = Raphael $("#canvas")
	circles = paper.set()

	paperClick = (ev, x, y) ->
		c = paper.circle x, y, 3
		c.attr
			fill: 'black'
			stroke: null

		c.click (ev, x, y) ->
			paper.raphael.unclick paperClick
			path = paper.path()
			path.attr { 'stroke-width': 2 }

			# Create a path and change attributes when mouse moves
			paper.raphael.mousemove (ev, x, y) =>
				path.attr { path: "M#{this.attrs.cx} #{this.attrs.cy} L#{x} #{y}" }

		c.hover ->
			this.attr
				fill: 'red'
		, ->
			this.attr
				fill: 'black'

		circles.push c

	snapToCircle = (ev, x, y) ->
		circles.forEach (c) ->
			distance = Math.sqrt Math.pow(c.attrs.cx - x, 2) + Math.pow(c.attrs.cy - y, 2)

	paper.raphael.click paperClick
	paper.raphael.mousemove snapToCircle

$ -> main()
