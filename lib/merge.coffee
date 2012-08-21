equal = require "deep-equal"
async = require "async"

module.exports = (log, root, cb) ->
  diff = {}
  check = (k, done) ->
    action = log[k]
    valid = equal action.current, root[k]
    return done() if valid
    done
      actual: root[k]
      current: action.current
      value: action.value

  performMerge = (k, done) ->
    action = log[k]
    diff[k] = root[k] = action.value
    done()

  async.forEach Object.keys(log), check, (conflict) ->
    return cb conflict if conflict?
    async.forEach Object.keys(log), performMerge, ->
      cb conflict, diff