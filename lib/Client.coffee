isBrowser = typeof window isnt "undefined"
if isBrowser
  Transaction = window.WarlockTransaction
else
  Transaction = require "./Transaction"

client = (opt) ->
  out =
    options:
      namespace: "Warlock"
      resource: "default"

    start: ->
      @root = {}
      @hasSynced = false
      return

    validate: (socket, msg, done) ->
      console.log "CLIENT", msg
      return done false unless typeof msg is "object"
      return done false unless typeof msg.type is "string"
      switch msg.type
        when "sync"
          return done false unless typeof msg.value is "object"
        when "complete", "failed"
          return done false unless typeof msg.id is "string"
        else
          return done false
      return done true

    close: (socket, reason) -> @emit "close", reason
    message: (socket, msg) ->
      switch msg.type
        when "sync"
          @root[k] = v for k,v of msg.value
          if @hasSynced
            @emit "sync", msg.value
          else
            @hasSynced = true
            @emit "ready"
        when "complete", "failed"
          @emit "#{msg.type}.#{msg.id}"
      return

    atomic: (fn) -> new Transaction fn, @
    ready: (fn) -> 
      if @hasSynced
        fn() 
      else 
        @once "ready", fn
      return
    subscribe: (fn) -> 
      @on "sync", fn

  out.options[k]=v for k,v of opt
  return out

if isBrowser
  window.Warlock = createClient: (opt={}) -> ProtoSock.createClient client opt
else
  module.exports = client