describe 'Rotate', ->
	describe '#next()', ->
		describe 'when initialized with [1, 2, 3]', ->
			before ->
				@numbers = new Rotate [1, 2, 3]

			it 'should return 1', ->
				expect(@numbers.next()).to.equal 1

			it 'should return 2', ->
				expect(@numbers.next()).to.equal 2

			it 'should return 3', ->
				expect(@numbers.next()).to.equal 3

			it 'should return 1', ->
				expect(@numbers.next()).to.equal 1
