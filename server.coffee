"use strict"

http = require("http")
path = require("path")

express = require("express")
passport = require("passport")

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
app.use express.cookieParser()
app.use express.bodyParser()
app.use express.methodOverride()

# development only
if "development" is app.get("env")
  app.use express.static(path.join(__dirname, ".tmp"))
  app.use express.static(path.join(__dirname, "app"))
  app.use express.errorHandler()
  app.set 'views', path.join(__dirname, "app")

# production only
else
  app.use express.favicon(path.join(__dirname, "public/favicon.ico"))
  app.use express.static(path.join(__dirname, "public"))
  app.set 'views', path.join(__dirname, "public")

app.use (err, req, res, next) ->
  logger.error "#{err}"
  next(err)

app.use express.cookieSession(
  secret: process.env.COOKIE_SECRET || "f67a2c22-a2f8-4eef-8e8f-a18d07d304f7"
)
app.use passport.initialize()
app.use passport.session()
passport.use api.auth.localStrategy
passport.use api.auth.bearerStrategy
# passport.use api.auth.baiduStrategy
passport.use api.auth.githubStrategy
passport.serializeUser api.auth.serializeUser
passport.deserializeUser api.auth.deserializeUser

app.use (req, res, next) ->  # disable cache for api
  if req.path.search(/\/api\//) is 0
    res.set 'Cache-Control', 'no-cache'
  next()
app.use app.router # api router

app.param "workstation", param.workstation
app.param "device", param.device
app.param "task", param.task
app.param "job", param.job

app.get "/api/awesomeThings", api.awesomeThings

app.get "/api/devices", api.auth.authAdmin, api.devices.list
app.get "/api/devices/:device", api.auth.authAdmin, api.devices.get
app.post "/api/devices/:device/tag/:tag", api.auth.authAdmin, api.devices.tag_device
app.post "/api/devices/:device/untag/:tag", api.auth.authAdmin, api.devices.untag_device
app.delete "/api/devices/:device/tag/:tag", api.auth.authAdmin, api.devices.untag_device
app.get "/api/devices/:device/screenshot", api.auth.authAdmin, api.devices.screenshot

app.get "/api/jobs", api.auth.authAdmin, api.jobs.list
app.get "/api/jobs/:job", api.auth.authAdmin, api.jobs.get
app.post "/api/jobs/:job/cancel", api.auth.authAdmin, api.jobs.cancel

app.get "/api/workstations", api.auth.authAdmin, api.workstations.get
app.get "/api/workstations/:workstation", api.auth.authAdmin, api.workstations.get
app.all "/api/workstations/:workstation/api/*", api.auth.authAdmin, api.workstations.api

app.post "/api/auth/get_access_token", api.auth.login
app.post "/api/auth/login", api.auth.login
app.post "/api/auth/logout", api.auth.auth, api.auth.logout
app.get "/api/account", api.auth.auth, api.account.get
app.post "/api/account", api.auth.auth, api.account.update
# app.get "/api/auth/baidu", passport.authenticate("baidu")
# app.get "/api/auth/baidu/callback", passport.authenticate("baidu", {failureRedirect: '/login', successRedirect: "/"})
app.get "/api/auth/github", passport.authenticate("github")
app.get "/api/auth/github/callback", passport.authenticate("github", {failureRedirect: '/login', successRedirect: "/"})

app.post "/api/projects", api.auth.auth, api.projects.add
app.get "/api/projects", api.auth.auth, api.projects.list
app.get "/api/projects/:project", api.auth.auth, api.auth.auth_project, api.projects.get
app.post "/api/projects/:project/add_user", api.auth.auth, api.auth.auth_project, api.projects.add_user
app.post "/api/projects/:project/remove_user", api.auth.auth, api.auth.auth_project, api.projects.rm_user
app.get "/api/projects/:project/devices", api.auth.auth, api.auth.auth_project, api.projects.list_devices
app.get "/api/projects/:project/devices/:device", api.auth.auth, api.auth.auth_project, api.projects.get_device

app.post "/api/tasks", api.auth.auth, api.auth.auth_project, api.tasks.add
app.get "/api/tasks", api.auth.auth, api.projects.param, api.tasks.list
app.get "/api/tasks/:task", api.auth.auth, api.auth.authTask, api.tasks.get
app.delete "/api/tasks/:task", api.auth.auth, api.auth.authTask, api.tasks.remove
app.post "/api/tasks/:task/cancel", api.auth.auth, api.auth.authTask, api.tasks.cancel
app.post "/api/tasks/:task/restart", api.auth.auth, api.auth.authTask, api.tasks.restart
app.post "/api/tasks/:task/jobs", api.auth.auth, api.auth.authTask, api.tasks.add_job
app.post "/api/tasks/:task/jobs/:no", api.auth.auth, api.auth.authTask, api.tasks.param_job_no, api.tasks.update_job
app.post "/api/tasks/:task/jobs/:no/cancel", api.auth.auth, api.auth.authTask, api.tasks.param_job_no, api.tasks.cancel_job
app.post "/api/tasks/:task/jobs/:no/restart", api.auth.auth, api.auth.authTask, api.tasks.param_job_no, api.tasks.restart_job
app.get "/api/tasks/:task/jobs/:no/stream", api.auth.auth, api.auth.authTask, api.tasks.param_job_no, api.tasks.job_output
app.get "/api/tasks/:task/jobs/:no/files/*", api.auth.auth, api.auth.authTask, api.tasks.param_job_no, api.tasks.job_files
app.get "/api/tasks/:task/jobs/:no/screenshot", api.auth.auth, api.auth.authTask, api.tasks.param_job_no, api.tasks.job_screenshot
app.get "/api/tasks/:task/jobs/:no/result", api.auth.auth, api.auth.authTask, api.tasks.param_job_no, api.tasks.job_result

app.get "/api/tags", api.auth.authAdmin, api.tags.get
app.post "/api/tags/:tag", api.auth.authAdmin, api.tags.add
app.post "/api/tags", api.auth.authAdmin, api.tags.add

app.post "/api/users", api.auth.authAdmin, api.users.add
app.get "/api/users", api.auth.authAdmin, api.users.list
app.get "/api/users/:id", api.auth.authAdmin, api.users.get
app.post "/api/users/:id", api.auth.authAdmin, api.users.update
app.post "/api/users/:id/tag/:tag", api.auth.authAdmin, api.users.tag
app.post "/api/users/:id/untag/:tag", api.auth.authAdmin, api.users.untag

app.get "/api/repos", api.repos.list
app.get "/api/repos/:user/:repo/readme", api.repos.readme
app.get "/api/repos/:user/:repo/env", api.repos.env

app.all "/api/*", (req, res) -> res.json 404, error: "API Not Found."

app.get '/views/*', routes.views
app.get '/*', (req, res) ->
  res.sendfile path.join(__dirname, "#{if 'development' is app.get('env') then 'app' else 'public'}/index.html")

http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port #{app.get('port')} in #{app.get('env')} mode."
