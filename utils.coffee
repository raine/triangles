class Rotate
	constructor: (@arr) ->
		@i = 0

	next: ->
		@i = 0 if @i is @arr.length
		@arr[@i++]
