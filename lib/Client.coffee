isBrowser = typeof window isnt 'undefined'
if isBrowser
  Transaction = window.WarlockTransaction
else
  Transaction = require './Transaction'

client = (opt) ->
  out =
    options:
      namespace: 'Warlock'
      resource: 'default'

    inbound: (socket, msg, done) ->
      try
        done JSON.parse msg
      catch err
        @error socket, err

    outbound: (socket, msg, done) ->
      try
        done JSON.stringify msg
      catch err
        @error socket,  err

    validate: (socket, msg, done) ->
      return done false unless typeof msg is 'object'
      return done false unless typeof msg.type is 'string'
      switch msg.type
        when 'sync'
          return done false unless typeof msg.id is 'string'
          return done false unless typeof msg.value is 'object'
        when 'retry', 'complete'
          return done false unless typeof msg.id is 'string'
        else
          return done false
      return done true

    close: (socket, reason) -> @emit 'close', reason
    message: (socket, msg) ->
      if msg.type is 'sync'
        socket.emit "sync.#{msg.id}", msg.value
      else if msg.type is 'retry'
        socket.emit "retry.#{msg.id}"
      else if msg.type is 'complete'
        socket.emit "complete.#{msg.id}"

    atomic: (fn) -> new Transaction fn, @ssocket

  out.options[k]=v for k,v of opt
  return out

if isBrowser
  window.Warlock = createClient: (opt={}) -> ProtoSock.createClient client opt
else
  module.exports = client