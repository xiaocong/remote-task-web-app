"use strict"

request = require("request")
url = require("url")
_ = require("underscore")
logger = require("../logger")

stop_job = (job, workstations)->
  if job?.get("status") is "started"
    ws = workstations.get job.get("device").workstation_mac
    url_str = url.format(
      protocol: "http"
      hostname: ws.get("ip")
      port: ws.get("api").port
      pathname: "/api/0/jobs/#{job.id}/stop"
    )
    request.get(url_str, (e, r, body)->)
    logger.info "Stop running job:#{job.id}."

exports = module.exports =
  kill_job_process: (job, workstations) ->
    stop_job(job, workstations)

  add: (req, res, next) ->
    jobs = req.param("jobs") ? [{}]
    return next new Error("Invalid jobs parameter!") if jobs not instanceof Array or jobs.length is 0
    name = req.param("name") ? "Task - #{new Date}"
    description = req.param("description") ? "Task created by #{req.user.email}(#{req.user.name}) at #{new Date} with #{jobs.length} job(s)."

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

    if not _.every(jobs, (j) -> j.repo_url?)
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
    running_only = (req.param("running_only") or "0") in ["1", "true", "t", "ok"]
    
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
    req.db.models.job.find({task_id: id, status: "started"}).each (job) ->
    req.zk.models.live_jobs.forEach (job) ->
      stop_job(job, req.zk.models.workstations) if job.get("status") is "started" and job.get("task_id") is id
    req.task.remove (err) ->
      return next(err) if err?
      req.db.models.job.find(task_id: id).remove (err) ->
        return next(err) if err?
        res.send 200
        req.redis.publish "db.task", JSON.stringify(method: "delete", task: id)
        logger.info "Task:#{id} removed."

  cancel: (req, res, next) ->
    id = req.task.id
    req.zk.models.live_jobs.forEach (job) ->
      stop_job(job, req.zk.models.workstations) if job.get("status") is "started" and job.get("task_id") is id
    req.db.models.job.find({task_id: id, status: ["new", "started"]}).each((job) ->
      job.status = "cancelled"
    ).save (err) ->
      req.redis.publish "db.task", JSON.stringify(method: "cancel", task: id)
      res.send 200
      logger.info "Task:#{id} cancelled."

  restart: (req, res, next) ->
    id = req.task.id
    req.zk.models.live_jobs.forEach (job) ->
      stop_job(job, req.zk.models.workstations) if job.get("status") is "started" and job.get("task_id") is id
    req.db.models.job.find({task_id: id}).each((job) ->
      job.status = "new"
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

  retrieve_job: (req, res, next) ->
    req.db.models.job.find {task_id: req.task.id, no: Number(req.params.no)}, (err, jobs) ->
      return next(err) if err?
      return res.json(404, error: "Job not found.") if jobs.length is 0
      req.job = jobs[0]
      next()

  update_job: (req, res, next) ->
    t_job = req.job
    if t_job.status is "started"
      return res.json 500, error: "Could not update started job."

    job = req.body
    if "r_job_nos" of job
      if job.r_job_nos not instanceof Array or _.some(job.r_job_nos, (n) -> n not in [0...req.task.jobs.length])
        return res.json 500, error: "Invalid r_job_nos."
    properties = ["r_type", "r_job_nos", "environ", "device_filter", "repo_url", "repo_branch", "repo_username", "repo_passowrd"]
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
        logger.info "Job:#{t_job.id} updated."

  cancel_job: (req, res, next) ->
    job = req.job
    if job.status in ["cancelled", "finished"]
      return res.json job
    stop_job(req.zk.models.live_jobs.get(job.id), req.zk.models.workstations)
    job.status = "cancelled"
    job.save (err) ->
      return next(err) if err?
      res.json job
      req.redis.publish "db.job", JSON.stringify(method: "cancel", job: job.id)
      logger.info "Job:#{job.id} cancelled."

  restart_job: (req, res, next) ->
    job = req.job
    if job.status is "new"
      return res.send 200
    stop_job(req.zk.models.live_jobs.get(job.id), req.zk.models.workstations)
    job.status = "new"
    job.save (err) ->
      return next(err) if err?
      res.json job
      req.redis.publish "db.job", JSON.stringify(method: "restart", job: job.id)
      logger.info "Job:#{job.id} restarted."

  job_output: (req, res, next) ->
    job = req.job
    if job.status is "new" or not job.device_id
      return res.json 400, error: "No output."
    req.db.models.device.get job.device_id, (err, dev) ->
      return next(err) if err?
      ws = req.zk.models.workstations.get(dev.workstation_mac)
      if ws?.get("api")?.status is "up"
        url_str = url.format(
          protocol: "http"
          hostname: ws.get("ip")
          port: ws.get("api").port
          pathname: "/api/0/jobs/#{job.id}/stream"
          query: req.query
        )
        req.pipe(request(url_str)).pipe(res)
      else
        res.json 404, error: "The workstation is disconnected."

  job_files: (req, res, next) ->
    job = req.job
    if job.status is "new" or not job.device_id
      return res.json 400, error: "No files available."
    req.db.models.device.get job.device_id, (err, dev) ->
      return next(err) if err?
      ws = req.zk.models.workstations.get(dev.workstation_mac)
      if ws?.get("api")?.status is "up"
        url_str = url.format(
          protocol: "http"
          hostname: ws.get("ip")
          port: ws.get("api").port
          pathname: "/api/0/jobs/#{job.id}/files/#{req.params[0]}"
          query: req.query
        )
        req.pipe(request(url_str)).pipe(res)
      else
        res.json 404, error: "The device is disconnected."
