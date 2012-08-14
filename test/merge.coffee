should = require 'should'
merge = require '../lib/merge'

describe 'merge', ->
  describe 'objects', ->
    it 'should merge non-pointer types', (done) ->
      root =
        test: 1
        test2: 2

      log =
        test:
          current: 1
          value: 3
      merged = merge log, root

      should.exist merged
      merged.should.be.true

      root.should.eql
        test: 3
        test2: 2
      done()

    it 'should merge pointer types', (done) ->
      root =
        test: [1]
        test2: 2

      log =
        test:
          current: [1]
          value: [1,3]
      merged = merge log, root

      should.exist merged
      merged.should.be.true

      root.should.eql
        test: [1,3]
        test2: 2
      done()

    it 'shouldnt merge non-pointer types with conflict', (done) ->
      root =
        test: 1
        test2: 2

      log =
        test:
          current: 2
          value: 3
      merged = merge log, root

      should.exist merged
      merged.should.be.false

      root.should.eql
        test: 1
        test2: 2
      done()

    it 'shouldnt merge pointer types with conflict', (done) ->
      root =
        test: [1]
        test2: 2

      log =
        test:
          current: [4]
          value: [1,3]
      merged = merge log, root

      should.exist merged
      merged.should.be.false

      root.should.eql
        test: [1]
        test2: 2
      done()