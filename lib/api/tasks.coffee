"use strict"

request = require("request")
url = require("url")
_ = require("underscore")
logger = require("../logger")

stop_job = (running_job)->
  logger.info running_job.toJSON()
  url_str = url.format(
    protocol: "http"
    hostname: running_job.get("ip")
    port: running_job.get("port")
    pathname: "/api/0/jobs/#{running_job.id}/stop"
  )
  request.get(url_str, (e, r, body)->)
  logger.info "Stop running job:#{running_job.id}."


exports = module.exports =
  add: (req, res, next) ->
    name = req.param("name")
    description = req.param("description") or ""
    jobs = req.param("jobs")
    return next(new Error("Invalid parameters!")) if not name?  or jobs not instanceof Array or jobs.length is 0

    properties = ["environ", "device_filter", "repo_url", "repo_branch", "repo_username", "repo_passowrd"]
    jobs.forEach (job, index) ->
      for prop in properties when prop not of job and req.param(prop)?
        job[prop] = req.param(prop)
      job["environ"] ?= {}
      job["r_type"] ?= "none"
      job["r_job_nos"] ?= []
      job["status"] = "new"
      job["no"] ?= index
      job["priority"] = req.project.priority  # 1 - 10. default 1 means lowest. 10 means highest.
      job["device_filter"] ?= {}
      job["device_filter"]["tags"] ?= []
      job["device_filter"]["tags"] = _.union(job["device_filter"]["tags"], req.project.tagList())

    if not name
      return res.json 500, error: "Empty task name."
    else if not _.every(jobs, (j) -> j.repo_url?)
      return res.json 500, error: "'repo_url' is mandatory for every job."
    else if _.size(_.countBy(jobs, (job) -> job.no)) isnt jobs.length
      return res.json 500, error: "Duplicated job no."
    else if not _.every(jobs, (j) -> j.device_filter?.tags?.length > 0)
      return res.json 500, error: "Every job should define at least one tag in 'device_filter.tags'."
    else if not _.isEqual(_.map(jobs, (job) -> job.no), [0...jobs.length])
      return res.json 500, error: "Job numbers should be continuous integers and start from 0."
    else if _.some(_.flatten(_.map(jobs, (job) -> job.r_job_nos)), (n) -> n not in [0...jobs.length])
      return res.json 500, error: "Invalid r_job_nos."

    req.db.models.task.create {name: name, description: description, creator_id: req.user.id, project_id: req.project.id}, (err, task) ->
      return next(err) if err?
      job.task_id = task.id for job in jobs
      req.db.models.job.create jobs, (err, jobs) ->
        return next(err) if err?
        task.jobs = jobs
        res.json task
        req.redis.publish "db.task", JSON.stringify(method: "add", task: task.id)

  get: (req, res, next) ->
    req.user.getProjects (err, projects) ->
      return next(err) if err?
      if req.task.project_id in _.map(projects, (proj) -> proj.id)
        task = JSON.parse(JSON.stringify(req.task))
        delete task.creator.password
        res.json task
      else
        res.json 403, error: "No permission to access the task."

  list: (req, res, next) ->
    page = Number(req.param("page")) or 0
    page_count = Number(req.param("page_count")) or 16
    running_only = (req.param("running_only") or "0") not in ["0", "false"]
    
    if running_only
      filter =  id: _.uniq(req.zk.models.live_jobs.map((job) -> job.get("task_id")))
    else
      filter = {}

    listTasks = ->
      req.db.models.task.find(filter).count (err, count) ->
        return next(err) if err?
        req.db.models.task.find(filter).order("-id").offset(page*page_count).limit(page_count).all (err, tasks) ->
          return next(err) if err?
          tasks = JSON.parse(JSON.stringify(tasks))
          delete task.creator.password for task in tasks
          res.json
            page: page
            page_count: page_count
            pages: Math.ceil(count/page_count)
            running_only: running_only
            tasks: tasks

    if req.project?
      filter.project_id = req.project.id
      listTasks()
    else
      filter.project_id = _.map(req.user.projects, (proj) -> proj.id)
      req.user.getProjects (err, projects) ->
        filter.project_id = _.map(projects, (proj) -> proj.id)
        listTasks()


  remove: (req, res, next) ->
    id = req.task.id
    req.task.jobs.forEach (job) ->
      stop_job(req.zk.models.jobs.get(job.id)) if req.zk.models.jobs.get(job.id)?  # stop the running job
    req.task.remove (err) ->
      return next(err) if err?
      req.db.models.job.find(task_id: id).remove (err) ->
        return next(err) if err?
        res.send 200
        req.redis.publish "db.task", JSON.stringify(method: "delete", task: id)
        logger.info "Task:#{id} removed."

  cancel: (req, res, next) ->
    id = req.task.id
    req.db.models.job.find({task_id: id, status: ["new", "started"]}).each((job) ->
      job.status = "cancelled"
      stop_job(req.zk.models.jobs.get(job.id)) if req.zk.models.jobs.get(job.id)?  # stop the running job
    ).save (err) ->
      req.redis.publish "db.task", JSON.stringify(method: "cancel", task: id)
      res.send 200
      logger.info "Task:#{id} cancelled."

  restart: (req, res, next) ->
    id = req.task.id
    req.db.models.job.find({task_id: id}).each((job) ->
      job.status = "new"
      stop_job(req.zk.models.jobs.get(job.id)) if req.zk.models.jobs.get(job.id)?  # stop the running job
    ).save (err) ->
      req.redis.publish "db.task", JSON.stringify(method: "restart", task: id)
      res.send 200
      logger.info "Task:#{id} re-started."

  add_job: (req, res, next) ->
    job = req.body
    job.task_id = req.task.id
    if not job.repo_url?
      return res.json 500, error: "'repo_url' is mandatory for job."
    job["environ"] ?= {}
    job["device_filter"] ?= {}
    job["device_filter"]["tags"] ?= []
    job["r_type"] ?= "none"
    job["r_job_nos"] ?= []
    job["status"] = "new"
    job["no"] = _.max(req.task.jobs, (j) -> j.no).no + 1
    req.db.models.project.get req.task.project_id, (err, project) ->
      return next(err) if err?
      job["priority"] = project.priority
      job["device_filter"]["tags"] = _.union(job["device_filter"]["tags"], project.tagList())

      if not job.device_filter?.tags?.length > 0
        return res.json 500, error: "Job should define at least one tag in 'device_filter.tags'."

      req.db.models.job.create job, (err, j) ->
        return next(err) if err?
        res.json j
        req.redis.publish "db.job", JSON.stringify(method: "add", job: j.id)

  update_job: (req, res, next) ->
    job = req.body
    job.no = Number(req.params.no)
    if "r_job_nos" of job
      if job.r_job_nos not instanceof Array or _.some(job.r_job_nos, (n) -> n not in [0...req.task.jobs.length])
        return res.json 500, error: "Invalid r_job_nos."
    if "status" of job and job.status not in ["new", "cancelled"]
      return res.json 500, error: "Invalide status."
    t_job = _.find(req.task.jobs, (j) -> j.no is job.no)
    if not t_job
      return res.json 500, error: "Job not found."
    if t_job.status is "started"
      return res.json 500, error: "Could not update started job."
    properties = ["status", "r_type", "r_job_nos", "environ", "priority", "device_filter", "repo_url", "repo_branch", "repo_username", "repo_passowrd"]
    t_job[prop] = job[prop] for prop in properties when prop of job
    req.db.models.project.get req.task.project_id, (err, project) ->
      return next(err) if err?
      t_job["priority"] = project.priority
      t_job.device_filter?.tags ?= []
      t_job["device_filter"]["tags"] = _.union(t_job["device_filter"]["tags"], project.tagList())
      t_job.save (err) ->
        return next(err) if err?
        res.json t_job
        req.redis.publish "db.job", JSON.stringify(method: "update", job: t_job.id)

  cancel_job: (req, res, next) ->
    job_no = Number(req.params.no)
    job = _.find(req.task.jobs, (job) -> job.no is job_no)
    if not job
      return res.json 500, error: "Job not found."
    if job.status in ["cancelled", "finished"]
      return res.send 200
    stop_job(req.zk.models.jobs.get(job.id)) if req.zk.models.jobs.get(job.id)?
    job.status = "cancelled"
    job.save (err) ->
      return next(err) if err?
      req.redis.publish "db.job", JSON.stringify(method: "cancel", job: job.id)
      res.send 200
      logger.info "Job:#{job.id} cancelled."

  restart_job: (req, res, next) ->
    job_no = Number(req.params.no)
    job = _.find(req.task.jobs, (job) -> job.no is job_no)
    if not job
      return res.json 500, error: "Job not found."
    if job.status is "new"
      return res.send 200
    stop_job(req.zk.models.jobs.get(job.id)) if req.zk.models.jobs.get(job.id)?
    job.status = "new"
    job.save (err) ->
      return next(err) if err?
      req.redis.publish "db.job", JSON.stringify(method: "restart", job: job.id)
      res.send 200
      logger.info "Job:#{job.id} restarted."
