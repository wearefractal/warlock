isBrowser = typeof window isnt "undefined"

getId = =>
  rand = -> (((1 + Math.random()) * 0x10000000) | 0).toString 16
  return rand()+rand()+rand()

cloneObj = (o) ->
  if typeof o is "object"
    if o.length?
      return (i for i in o)
    else
      nu = {}
      nu[k]=v for own k,v of o
      return nu
  else
    return o

class Transaction
  constructor: (@fn, @parent) ->
    @log = {}
    @root = {}
    @id = getId()

  run: (cb) =>
    @parent.ready => @doTrans cb

  doTrans: (cb) =>
    @root = cloneObj @parent.root
    ctx =
      get: (k) => cloneObj @root[k]
      set: (k, v) =>
        @log[k] ?= current: ctx.get k
        @log[k].value = v
        @root[k] = v
        return ctx

      # sugar
      delete: (k) => ctx.set k, undefined
      incr: (k, v=1) => ctx.set k, ctx.get(k)+v
      decr: (k, v=1) => ctx.set k, ctx.get(k)-v
      push: (k, v) => 
        temp = ctx.get k
        temp.push v
        ctx.set k, temp
      unshift: (k, v) => 
        temp = ctx.get k
        temp.unshift v
        ctx.set k, temp

      retry: => @parent.once "sync", ctx.restart
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
          type: "transaction"
          id: @id
          log: @log

    @fn.call ctx
    return
      
if isBrowser
  window.WarlockTransaction = Transaction
else
  module.exports = Transaction