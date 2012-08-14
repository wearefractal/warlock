equal = require 'deep-equal'

module.exports = (log, root) ->
  valid = true
  for k, action of log
    valid = equal action.current, root[k]
    continue if valid
    break

  if valid
    root[k] = action.value for k, action of log
    return true
  else
    return false