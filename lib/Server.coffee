merge = require "./merge"
async = require "async"

module.exports =
  options:
    namespace: "Warlock"
    resource: "default"

  start: -> 
    @root = {}
    @stack = {}

  validate: (socket, msg, done) ->
    return done false unless typeof msg is "object"
    return done false unless typeof msg.type is "string"
    switch msg.type
      when "transaction"
        return done false unless typeof msg.id is "string"
        return done false unless typeof msg.log is "object" and !Array.isArray msg.log
        verifyAction = (k, done) =>
          action = msg.log[k]
          return done false unless typeof action is "object" and !Array.isArray msg.log
          return done false unless typeof k is "string"
          # action.value can be any value (set) or undefined (delete)
          # action.current can be any value (replace) or undefined (create)
        async.forEach Object.keys(msg.log), verifyAction, done
      else
        return done false
    return done true

  connect: (socket) -> @sync socket

  sync: (socket, diff=@root) ->
    socket.write
      type: "sync"
      value: diff

  syncAll: (diff=@root, cb) ->
    async.forEach Object.keys(@server.clients),
      (id, done) =>
        @sync @server.clients[id], diff
        done()
      , cb

  message: (socket, msg) ->
    @runStacks socket, msg.log, =>
      merge msg.log, @root, (conflict, diff) =>
        if conflict?
          @sync socket
          socket.write
            type: "failed"
            id: msg.id
          @emit "failed", msg
        else
          @syncAll diff, =>
            socket.write
              type: "complete"
              id: msg.id
            @emit "complete", msg
  
  use: (k, fn) -> (@stack[k]?=[]).push fn

  runStacks: (socket, log, cb) ->
    run = (k, done) =>
      return done() unless @stack[k]? and @stack[k].length isnt 0
      runrl = (middle, done) =>
        trans =
          key: k
          current: log[k].current
          value: log[k].value
        middle socket, trans, =>
          log[k].value = trans.value
          done()

      async.forEachSeries @stack[k], runrl, done
    async.forEachSeries Object.keys(log), run, cb
    return

  add: (obj) ->
    addObject = (ns, nobj) =>
      ns = "#{ns}." unless ns is ""
      for k,v of nobj
        if typeof v is "object" and !Array.isArray v
          addObject "#{ns}#{k}", v
        else
          @root["#{ns}#{k}"] = v
    addObject "", obj