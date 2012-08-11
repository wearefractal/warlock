equal = require 'deep-equal'

module.exports = (opt) ->
  out =
    options:
      namespace: 'Warlock'
      resource: 'default'

    start: -> 
      @root = {}

    inbound: (socket, msg, done) ->
      #console.log 'in', msg
      try
        done JSON.parse msg
      catch err
        @error socket, err

    outbound: (socket, msg, done) ->
      #console.log 'out', msg
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
        else
          return done false
      return done true

    connect: (socket) ->
      socket.write
        type: 'sync'
        value: @root

    close: (socket, reason) -> @emit 'close', reason
    message: (socket, msg) ->
      return unless msg.type is 'transaction'
      valid = true
      for k, action of msg.log
        valid = equal action.current, @root[k]
        continue if valid
        break

      if valid
        @root[k] = action.value for k, action of msg.log
        for id, client of @server.clients
          # TODO: sync only changed keys
          client.write
            type: 'sync'
            value: @root

        socket.write
          type: 'complete'
          id: msg.id
      else
        socket.write
          type: 'sync'
          value: @root
        socket.write
          type: 'failed'
          id: msg.id
          

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