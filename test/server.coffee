http = require 'http'
should = require 'should'
Warlock = require '../'
{join} = require 'path'

randomPort = -> Math.floor(Math.random() * 1000) + 8000

getServer = ->
  Warlock.createServer
    server: http.createServer().listen randomPort()

getClient = (server) -> 
  Warlock.createClient 
    host: server.server.httpServer.address().address
    port: server.server.httpServer.address().port
    resource: server.options.resource

describe 'Warlock', ->
  describe 'objects', ->
    it 'should add', (done) ->
      serv = getServer()
      serv.add 
        test: 'test'
        nest:
          nest:
            nest: 'nest'

      should.exist serv.root
      should.exist serv.root['test']
      should.exist serv.root['nest.nest.nest']
      done()

  describe 'transactions', ->
    it 'should sync on connect', (done) ->
      serv = getServer()

      client = getClient serv
      client.ready done

    it 'should get', (done) ->
      serv = getServer()
      test = hello: 'world'
      serv.add test

      client = getClient serv
      trans = client.atomic ->
        should.exist @get
        should.exist @get 'hello'
        @get('hello').should.equal 'world'
        done()

      trans.run()

    it 'should set', (done) ->
      serv = getServer()
      test = hello: 'world'
      serv.add test

      client = getClient serv
      trans = client.atomic ->
        should.exist @get 'hello'
        @get('hello').should.equal 'world'
        should.exist @set
        @set 'hello', 'mars'
        @get('hello').should.equal 'mars'
        done()

      trans.run()

    it 'should run middleware on set', (done) ->
      serv = getServer()
      test = hello: 'world'
      serv.add test

      client = getClient serv
      trans = client.atomic ->
        @set 'hello', 'mars'
        @done()

      serv.use 'hello', (socket, trans, next) ->
        should.exist socket
        should.exist trans
        should.exist trans.key
        should.exist trans.current
        should.exist trans.value
        should.exist next
        trans.key.should.equal 'hello'
        trans.current.should.equal 'world'
        trans.value.should.equal 'mars'
        done()


      trans.run()

    it 'should run mutating middleware on set', (done) ->
      serv = getServer()
      test = hello: 'world'
      serv.add test

      client = getClient serv
      trans = client.atomic ->
        @set 'hello', 'mars'
        @done()

      serv.use 'hello', (socket, trans, next) ->
        trans.value = 'venus'
        next()

      trans.run ->
        should.exist serv.root.hello
        serv.root.hello.should.equal 'venus'
        done()

    it 'should incr', (done) ->
      serv = getServer()
      test = hello: 1
      serv.add test

      client = getClient serv
      trans = client.atomic ->
        @incr 'hello'
        @done()

      trans.run ->
        serv.root.hello.should.equal 2
        done()

    it 'should decr', (done) ->
      serv = getServer()
      test = hello: 1
      serv.add test

      client = getClient serv
      trans = client.atomic ->
        @decr 'hello'
        @done()

      trans.run ->
        serv.root.hello.should.equal 0
        done()

    it 'should push', (done) ->
      serv = getServer()
      test = hello: [1]
      serv.add test

      client = getClient serv
      trans = client.atomic ->
        @push 'hello', 2
        @done()

      trans.run ->
        serv.root.hello.should.eql [1,2]
        done()

    it 'should unshift', (done) ->
      serv = getServer()
      test = hello: [1]
      serv.add test

      client = getClient serv
      trans = client.atomic ->
        @unshift 'hello', 2
        @done()

      trans.run ->
        serv.root.hello.should.eql [2,1]
        done()

    it 'should complete with no ops', (done) ->
      serv = getServer()
      serv.add {}

      client = getClient serv
      trans = client.atomic -> @done()
      trans.run done

    it 'should complete with set', (done) ->
      serv = getServer()
      test = hello: 'world', test: 'test'
      serv.add test

      client = getClient serv
      trans = client.atomic ->
        @set 'hello', 'mars'
        @set 'newProp', true
        @set 'test', undefined
        @done()

      trans.run ->
        serv.root.hello.should.equal 'mars'
        serv.root.newProp.should.equal true
        should.not.exist serv.root.test
        done()

    it 'should complete with incr', (done) ->
      serv = getServer()
      test = hello: 1
      serv.add test
      client = getClient serv
      trans = client.atomic ->
        @incr 'hello'
        @done()

      trans.run ->
        serv.root.hello.should.equal 2
        done()

    it 'should complete with decr', (done) ->
      serv = getServer()
      test = hello: 1
      serv.add test
      client = getClient serv
      trans = client.atomic ->
        @decr 'hello'
        @done()

      trans.run ->
        serv.root.hello.should.equal 0
        done()

    it 'should retry if called', (done) ->
      serv = getServer()
      test = hello: 'world'
      serv.add test

      client = getClient serv
      secondary = ->
        trans = client.atomic ->
          @set 'hello', 'venus'
          @done()
        trans.run()

      trans = client.atomic ->
        if @get('hello') is 'world'
          @retry()
          secondary()
        else if @get('hello') is 'venus'
          @set 'hello', 'mars'
          @done()

      trans.run ->
        serv.root.hello.should.equal 'mars'
        done()

    it 'should retry with conflict', (done) ->
      serv = getServer()
      test = hello: 'world'
      serv.add test

      client = getClient serv
      trans = client.atomic ->
        if @get('hello') is 'world'
          serv.root.hello = 'venus' # simulate change
          @set 'hello', 'mars'
          @done()
        else if @get('hello') is 'venus'
          @set 'hello', 'marsi'
          @done()

      trans.run ->
        serv.root.hello.should.equal 'marsi'
        done()

    it 'should restart if called', (done) ->
      serv = getServer()
      test = hello: 'world'
      serv.add test
      last = 0

      client = getClient serv

      trans = client.atomic ->
        if last is 0
          last = 1
          @restart()
        else
          @set 'hello', 'mars'
          @done()

      trans.run ->
        serv.root.hello.should.equal 'mars'
        done()

    it 'should abort if called', (done) ->
      serv = getServer()
      test = hello: 'world'
      serv.add test

      client = getClient serv
      trans = client.atomic -> @abort()
      trans.run (err) ->
        should.exist err
        done()

    it 'should abort with message if called', (done) ->
      serv = getServer()
      test = hello: 'world'
      serv.add test

      client = getClient serv
      trans = client.atomic -> @abort 'something broke'
      trans.run (err) ->
        should.exist err
        (err.message.indexOf('something broke') > -1).should.be.true
        done()

    it 'should subscribe to all changes', (done) ->
      serv = getServer()
      test = hello: 'world'
      serv.add test

      client = getClient serv

      test = ->
        client.subscribe (root) ->
          should.exist root
          should.exist root.hello
          root.hello.should.equal 'mars'
          done()

        trans = client.atomic ->
          @set 'hello', 'mars'
          @done()
        trans.run()

      setTimeout test, 1000