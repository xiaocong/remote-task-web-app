"use strict"

express = require("express")
http = require("http")
path = require("path")

logger = require("./lib/logger")
api = require("./lib/api")
dbmodule = require("./lib/module")
param = require("./lib/param")
routes = require("./lib/routes")

app = express()

# all environments
app.set "port", process.env.PORT or 3000
app.engine 'html', require('ejs').renderFile
app.set 'view engine', 'html'
app.enable 'trust proxy'

app.use express.logger(stream: {write: (msg, encode) -> logger.info(msg)})
app.use dbmodule.setup()
app.use express.bodyParser()
app.use express.methodOverride()

app.use app.router

# development only
if "development" is app.get("env")
  app.use express.static(path.join(__dirname, ".tmp"))
  app.use express.static(path.join(__dirname, "app"))
  app.use (req, res, next) -> res.sendfile path.join(__dirname, "app/index.html")
  app.use express.errorHandler()
  app.set 'views', path.join(__dirname, "app")

# production only
else
  app.use express.favicon(path.join(__dirname, "public/favicon.ico"))
  app.use express.static(path.join(__dirname, "public"))
  app.use (req, res, next) -> res.sendfile path.join(__dirname, "public/index.html")
  app.set 'views', path.join(__dirname, "public")

app.use (err, req, res, next) ->
  logger.error "#{err}"
  next(err)

app.param "workstation", param.workstation
app.param "device", param.device
app.param "task", param.task
app.param "job", param.job

app.get "/api/awesomeThings", api.awesomeThings

app.get "/api/devices", api.auth.auth_admin, api.devices.list
app.get "/api/devices/:device", api.auth.auth_admin, api.devices.get
app.post "/api/devices/:device/tag/:tag", api.auth.auth_admin, api.devices.tag_device
app.post "/api/devices/:device/untag/:tag", api.auth.auth_admin, api.devices.untag_device
app.delete "/api/devices/:device/tag/:tag", api.auth.auth_admin, api.devices.untag_device

app.get "/api/jobs", api.auth.auth_admin, api.jobs.list
app.get "/api/jobs/:job", api.auth.auth_admin, api.jobs.get
app.post "/api/jobs/:job/cancel", api.auth.auth_admin, api.jobs.cancel

app.get "/api/workstations", api.auth.auth_admin, api.workstations.get
app.get "/api/workstations/:workstation", api.auth.auth_admin, api.workstations.get
app.all "/api/workstations/:workstation/api/*", api.auth.auth_admin, api.workstations.api

app.post "/api/auth/get_access_token", api.auth.get_access_token
app.get "/api/account", api.auth.auth, api.account.get
app.post "/api/account", api.auth.auth, api.account.update

app.post "/api/projects", api.auth.auth, api.projects.add
app.get "/api/projects", api.auth.auth, api.projects.list
app.get "/api/projects/:project", api.auth.auth, api.auth.auth_project, api.projects.get
app.post "/api/projects/:project/add_user", api.auth.auth, api.auth.auth_project, api.projects.add_user
app.post "/api/projects/:project/remove_user", api.auth.auth, api.auth.auth_project, api.projects.rm_user
app.get "/api/projects/:project/devices", api.auth.auth, api.auth.auth_project, api.projects.list_devices
app.get "/api/projects/:project/devices/:device", api.auth.auth, api.auth.auth_project, api.projects.get_device

app.post "/api/tasks", api.auth.auth, api.auth.auth_project, api.tasks.add
app.get "/api/tasks", api.auth.auth, api.projects.param, api.tasks.list
app.get "/api/tasks/:task", api.auth.auth, api.auth.auth_task, api.tasks.get
app.delete "/api/tasks/:task", api.auth.auth, api.auth.auth_task, api.tasks.remove
app.post "/api/tasks/:task/cancel", api.auth.auth, api.auth.auth_task, api.tasks.cancel
app.post "/api/tasks/:task/restart", api.auth.auth, api.auth.auth_task, api.tasks.restart
app.post "/api/tasks/:task/jobs", api.auth.auth, api.auth.auth_task, api.tasks.add_job
app.post "/api/tasks/:task/jobs/:no", api.auth.auth, api.auth.auth_task, api.tasks.retrieve_job, api.tasks.update_job
app.post "/api/tasks/:task/jobs/:no/cancel", api.auth.auth, api.auth.auth_task, api.tasks.retrieve_job, api.tasks.cancel_job
app.post "/api/tasks/:task/jobs/:no/restart", api.auth.auth, api.auth.auth_task, api.tasks.retrieve_job, api.tasks.restart_job
app.get "/api/tasks/:task/jobs/:no/stream", api.auth.auth, api.auth.auth_task, api.tasks.retrieve_job, api.tasks.job_output
app.get "/api/tasks/:task/jobs/:no/files/*", api.auth.auth, api.auth.auth_task, api.tasks.retrieve_job, api.tasks.job_files

app.get "/api/tags", api.auth.auth_admin, api.tags.get
app.post "/api/tags/:tag", api.auth.auth_admin, api.tags.add
app.post "/api/tags", api.auth.auth_admin, api.tags.add

app.post "/api/users", api.auth.auth_admin, api.users.add
app.get "/api/users", api.auth.auth_admin, api.users.list
app.get "/api/users/:id", api.auth.auth_admin, api.users.get
app.post "/api/users/:id", api.auth.auth_admin, api.users.update

app.all "/api/*", (req, res) -> res.json 404, error: "API Not Found."

app.get '/views/*', routes.views

http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port #{app.get('port')} in #{app.get('env')} mode."
