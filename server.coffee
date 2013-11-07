"use strict"

express = require("express")
http = require("http")
path = require("path")
redis = require("redis")

api = require("./lib/api")
module = require("./lib/module")
param = require("./lib/param")

app = express()

# all environments
require("./lib/config") app  # set configurations
app.use express.logger("dev")
app.use express.bodyParser()
app.use express.methodOverride()
app.use module.database(app.get "mysql_url")
app.use module.redis(app.get "redis_url")
app.use module.zk(app.get("zk_url"), app.get("zk_path"))
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

app.param "workstation", param.workstation

app.get "/api/awesomeThings", api.awesomeThings
app.get "/api/devices", api.devices
app.get "/api/workstations", api.workstations
app.all ///^/api/workstations/([\d\w:]+)/api/(.+)$///, api.workstation_api

http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port %d in %s mode", app.get("port"), app.get("env")

