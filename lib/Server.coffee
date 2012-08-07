equal = require 'deep-equal'

module.exports = (opt) ->
  out =
    options:
      namespace: 'Warlock'
      resource: 'default'

    start: -> @root = {}

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
        when 'transaction'
          return done false unless typeof msg.id is 'string'
          return done false unless typeof msg.log is 'object' and !Array.isArray msg.log
          for k,action of msg.log
            return done false unless typeof action is 'object' and !Array.isArray msg.log
            return done false unless typeof k is 'string'
            # action.value can be any value (set) or undefined (delete)
            # action.current can be any value (replace) or undefined (create)
        when 'sync', 'retry'
          return done false unless typeof msg.id is 'string'
        else
          return done false
      return done true

    close: (socket, reason) -> @emit 'close', reason
    message: (socket, msg) ->
      if msg.type is 'transaction'
        for k, action of msg.log
          if equal action.current, @root[k]
            @root[k] = action.value
            continue
          else
            socket.write
              type: 'retry'
              id: msg.id
            return
        @emit 'transaction', msg
        socket.write
          type: 'complete'
          id: msg.id
        return
      else if msg.type is 'sync'
        socket.write
          type: 'sync'
          id: msg.id
          value: @root
        return
      else if msg.type is 'retry'
        @once 'transaction', =>
          socket.write
            type: 'retry'
            id: msg.id
          return
        return
          

    add: (obj) ->
      addObject = (ns, nobj) =>
        ns = "#{ns}." unless ns is ''
        for k,v of nobj
          if typeof v is 'object' and !Array.isArray v
            addObject "#{ns}#{k}", v
          else
            @root["#{ns}#{k}"] = v
      addObject '', obj

  out.options[k]=v for k,v of opt
  return out