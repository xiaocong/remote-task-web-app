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
module.setup app  # setup global db/zk/redis instance

app.use express.logger("dev")
app.use module.database()
app.use module.redis()
app.use module.zk()
app.use express.bodyParser()
app.use express.methodOverride()
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
app.param "device", param.device

app.get "/api/awesomeThings", api.awesomeThings
app.get "/api/devices", api.devices
app.get "/api/devices/:device", api.devices
app.post "/api/devices/:device/tag/:tag_name/:tag_value", api.tag_device
app.delete "/api/devices/:device/tag/:tag_name/:tag_value", api.untag_device
app.get "/api/workstations", api.workstations
app.get "/api/workstations/:workstation", api.workstations
app.all ///^/api/workstations/([\d\w:]+)/api/(.+)$///, api.workstation_api

app.get "/api/tags", api.tags
app.get "/api/tags/:tag_name", api.tags
app.post "/api/tags/:tag_name/:tag_value", api.tags_create

http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port #{app.get('port')} in #{app.get('env')} mode."
