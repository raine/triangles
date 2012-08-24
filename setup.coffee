DEBUG = true

oldLog = console.log

console.log = ->
	oldLog.apply this, arguments if DEBUG

$ ->
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
