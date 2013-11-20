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

app.use express.logger(stream: {write: (msg, encode) -> logger.info(msg)})
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
app.param "task", param.task

app.get "/api/awesomeThings", api.awesomeThings

app.get "/api/devices", api.auth.authenticate, api.devices.get
app.get "/api/devices/:device", api.auth.authenticate, api.devices.get
app.post "/api/devices/:device/tag/:tag", api.auth.authenticate, api.devices.tag_device
app.post "/api/devices/:device/untag/:tag", api.auth.authenticate, api.devices.untag_device
app.delete "/api/devices/:device/tag/:tag", api.auth.authenticate, api.devices.untag_device
app.get "/api/workstations", api.auth.authenticate, api.workstations.get
app.get "/api/workstations/:workstation", api.auth.authenticate, api.workstations.get
app.all ///^/api/workstations/([\d\w:]+)/api/(.+)$///, api.auth.authenticate, api.workstations.api

app.post "/api/auth/get_access_token", api.auth.get_access_token
app.get "/api/account", api.auth.authenticate, api.account.get
app.post "/api/account", api.auth.authenticate, api.account.update

app.post "/api/tasks", api.auth.authenticate, api.tasks.add
app.get "/api/tasks", api.auth.authenticate, api.tasks.list
app.get "/api/tasks/:task", api.auth.authenticate, api.tasks.get
app.delete "/api/tasks/:task", api.auth.authenticate, api.tasks.remove
app.post "/api/tasks/:task/cancel", api.auth.authenticate, api.tasks.cancel
app.post "/api/tasks/:task/restart", api.auth.authenticate, api.tasks.restart
app.post "/api/tasks/:task/jobs", api.auth.authenticate, api.tasks.add_job
app.post "/api/tasks/:task/jobs/:no", api.auth.authenticate, api.tasks.update_job
app.post "/api/tasks/:task/jobs/:no/cancel", api.auth.authenticate, api.tasks.cancel_job
app.post "/api/tasks/:task/jobs/:no/restart", api.auth.authenticate, api.tasks.restart_job

app.get "/api/tags", api.auth.authenticate, api.tags.get
app.post "/api/tags/:tag", api.auth.admin_auth, api.tags.add
app.post "/api/tags", api.auth.admin_auth, api.tags.add

app.post "/api/users", api.auth.admin_auth, api.users.add
app.get "/api/users", api.auth.admin_auth, api.users.list
app.get "/api/users/:id", api.auth.admin_auth, api.users.get

http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port #{app.get('port')} in #{app.get('env')} mode."
