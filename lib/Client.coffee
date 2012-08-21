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
      @synced = false
      @subscribers = {}
      @on "sync", @runSubscribers
      return

    validate: (socket, msg, done) ->
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

    message: (socket, msg) ->
      switch msg.type
        when "sync"
          @root[k] = v for k,v of msg.value
          if @synced
            @emit "sync", msg.value
          else
            @synced = true
            @emit "ready"
        when "complete", "failed"
          @emit "#{msg.type}.#{msg.id}"
      return

    atomic: (fn) -> new Transaction fn, @
    ready: (fn) -> 
      if @synced
        fn() 
      else 
        @once "ready", fn

    subscribe: (kp, fn) -> (@subscribers[kp]?=[]).push fn
    runSubscribers: (diff) ->
      for kp, nu of diff when @subscribers[kp]?
        listener kp, nu for listener in @subscribers[kp]
      return

  out.options[k]=v for k,v of opt
  return out

if isBrowser
  window.Warlock = createClient: (opt={}) -> ProtoSock.createClient client opt
  #define(->Warlock) if typeof define is 'function'
else
  module.exports = client