isBrowser = typeof window isnt 'undefined'

getId = =>
  rand = -> (((1 + Math.random()) * 0x10000000) | 0).toString 16
  return rand()+rand()+rand()

class Transaction
  constructor: (@fn, @socket) ->
    @log = {}
    @id = getId()

  run: (cb) =>
    @socket.write
      type: 'sync'
      id: @id

    @socket.once "sync.#{@id}", (root) =>
      ctx =
        get: (k) => root[k]
        set: (k, v) =>
          @log[k] ?= current: root[k]
          @log[k].value = v
          root[k] = v
          return ctx

        # sugar
        delete: (k) =>
          ctx.set k, undefined
          return ctx
        incr: (k, v=1) =>
          ctx.set k, k+v
          return ctx
        decr: (k, v=1) =>
          ctx.set k, k-v
          return ctx

        retry: =>
          @socket.write
            type: 'retry'
            id: @id
          return

        restart: =>
          @socket.removeAllListeners "retry.#{@id}"
          @socket.removeAllListeners "complete.#{@id}"
          @log = {}
          @run cb
          return

        abort: (msg) => 
          emsg = "Transaction aborted"
          emsg += ": #{msg}" if msg?
          cb new Error emsg
          return

        done: =>
          @socket.write
            type: 'transaction'
            id: @id
            log: @log
          @socket.once "complete.#{@id}", cb
          return

      @socket.once "retry.#{@id}", ctx.restart
      @fn.call ctx
      
if isBrowser
  window.WarlockTransaction = Transaction
else
  module.exports = Transaction