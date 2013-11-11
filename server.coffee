"use strict"

express = require("express")
http = require("http")
path = require("path")

logger = require("./lib/logger")
api = require("./lib/api")
dbmodule = require("./lib/module")
param = require("./lib/param")

app = express()

# all environments
app.set "port", process.env.PORT or 3000
app.enable('trust proxy')

app.use express.logger("dev")
app.use dbmodule.setup()
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

app.use (err, req, res, next) ->
  if err?
    logger.error "#{err}"
    if req.path[..4] is "/api/"
      res.json 500, error: "#{err}"
    else
      res.send 500, "Server Error"  #TODO error page
  else
    next()

app.param "workstation", param.workstation
app.param "device", param.device

app.get "/api/awesomeThings", api.awesomeThings

app.get "/api/devices", api.auth.authenticate, api.devices.get
app.get "/api/devices/:device", api.auth.authenticate, api.devices.get
app.post "/api/devices/:device/tag/:tag_name/:tag_value", api.auth.authenticate, api.devices.tag_device
app.post "/api/devices/:device/untag/:tag_name/:tag_value", api.auth.authenticate, api.devices.untag_device
app.delete "/api/devices/:device/tag/:tag_name/:tag_value", api.auth.authenticate, api.devices.untag_device
app.get "/api/workstations", api.auth.authenticate, api.workstations.get
app.get "/api/workstations/:workstation", api.auth.authenticate, api.workstations.get
app.all ///^/api/workstations/([\d\w:]+)/api/(.+)$///, api.auth.authenticate, api.workstations.api

app.post "/api/auth/get_access_token", api.auth.get_access_token
app.get "/api/account", api.auth.authenticate, api.account.get
app.post "/api/account", api.auth.authenticate, api.account.update

app.get "/api/tags", api.auth.authenticate, api.tags.get
app.get "/api/tags/:tag_name", api.auth.authenticate, api.tags.get
app.post "/api/tags/:tag_name/:tag_value", api.auth.admin_auth, api.tags.add
app.post "/api/tags", api.auth.admin_auth, api.tags.add

app.post "/api/users", api.auth.admin_auth, api.users.add
app.get "/api/users", api.auth.admin_auth, api.users.list
app.get "/api/users/:id", api.auth.admin_auth, api.users.get

http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port #{app.get('port')} in #{app.get('env')} mode."
