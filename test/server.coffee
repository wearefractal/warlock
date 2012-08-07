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