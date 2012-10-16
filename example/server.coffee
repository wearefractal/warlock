connect = require "connect"
Warlock = require "../"

# Web server
webServer = connect()
webServer.use connect.favicon()
webServer.use connect.staticCache()
webServer.use connect.static "#{__dirname}/public"

server = webServer.listen app.web.port

# Vein
lock = new Warlock.createServer server: server
lock.add todos: []

console.log "Server started on #{app.web.port}"