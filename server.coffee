"use strict"

express = require("express")
http = require("http")
path = require("path")
api = require("./lib/api")
module = require("./lib/module")

app = express()

# all environments
app.set "port", process.env.PORT or 3000
app.use express.logger("dev")
app.use express.bodyParser()
app.use express.methodOverride()
app.use module.database("mysql://test:12345@localhost/remote_task?debug=true")
app.use module.zk("localhost:2181", "/remote/alive/workstation")
app.use app.router

# development only
if "development" is app.get("env")
  app.use express.static(path.join(__dirname, ".tmp"))
  app.use express.static(path.join(__dirname, "app"))
  app.use express.errorHandler()

# production only
else
  app.use express.favicon(path.join(__dirname, "public/favicon.ico"))
  app.use express.static(path.join(__dirname, "public"))

app.get "/api/awesomeThings", api.awesomeThings
app.get "/api/devices", api.devices

http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port %d in %s mode", app.get("port"), app.get("env")

