isBrowser = typeof window isnt 'undefined'

getId = =>
  rand = -> (((1 + Math.random()) * 0x10000000) | 0).toString 16
  return rand()+rand()+rand()

class Transaction
  constructor: (@fn, @parent) ->
    @log = {}
    @root = {}
    @id = getId()

  run: (cb) =>
    if @parent.hasSynced
      @doTrans cb
    else
      @parent.once 'sync', => @doTrans cb


  doTrans: (cb) =>
    @root[k] = v for k,v of @parent.root
    ctx =
      get: (k) => @root[k]
      set: (k, v) =>
        @log[k] ?= current: @root[k]
        @log[k].value = v
        @root[k] = v
        return ctx

      # sugar
      delete: (k) => ctx.set k, undefined
      incr: (k, v=1) => ctx.set k, ctx.get(k)+v
      decr: (k, v=1) => ctx.set k, ctx.get(k)-v

      retry: => @parent.once 'sync', ctx.restart

      restart: =>
        @parent.removeAllListeners "failed.#{@id}"
        @parent.removeAllListeners "complete.#{@id}"
        @log = {}
        @root = {}
        @run cb

      abort: (msg) =>
        emsg = "Transaction aborted"
        emsg += ": #{msg}" if msg?
        cb new Error emsg

      done: =>
        @parent.once "complete.#{@id}", cb if cb?
        @parent.once "failed.#{@id}", ctx.restart
        @parent.ssocket.write
          type: 'transaction'
          id: @id
          log: @log

    @fn.call ctx
    return
      
if isBrowser
  window.WarlockTransaction = Transaction
else
  module.exports = Transaction