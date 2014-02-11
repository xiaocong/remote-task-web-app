"use strict"

request = require("request")
url = require("url")
_ = require("underscore")
logger = require("../logger")
devices = require("./devices")

stop_job = (job, workstations)->
  if job?.get("status") is "started"
    ws = workstations.get job.get("device").workstation_mac
    url_str = url.format(
      protocol: "http"
      hostname: ws.get("ip")
      port: ws.get("api").port
      pathname: "#{ws.get('api').path}/0/jobs/#{job.id}/stop"
    )
    request.get(url_str, (e, r, body)->)
    logger.info "Stop running job:#{job.id}."

retrieve_task = (req, res, next, id) ->
  req.db.models.task.get id, (err, task) ->
    task = JSON.parse(JSON.stringify(task))
    delete task.creator.password
    res.json task

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
      job.environ ?= {}
      job.r_type ?= "none"
      job.r_job_nos ?= []
      job.status = "new"
      job.no ?= index
      job.priority = req.project.priority  # 1 - 10. default 1 means lowest. 10 means highest.
      job.device_filter ?= {}
      job.device_filter.tags ?= []
      job.device_filter.tags = _.union(job.device_filter.tags, req.project.tagList())
      job.device_filter.device_owner = req.project.creator.email

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
    task = JSON.parse(JSON.stringify(req.task))
    delete task.creator.password
    _.each task.jobs, (job) ->
      filter = job.device_filter or {}
      schedular =
        available_device:
          total: 0
          idle: 0
        has_exclusive: false
        has_dependency: false
      req.data.models.devices.filter((dev) ->
        req.methods.match filter, dev
      ).forEach (dev) ->
        schedular.available_device.total += 1
        schedular.available_device.idle += 1 if dev.get "idle"
      schedular.has_exclusive = req.methods.has_exclusive job
      schedular.has_dependency = req.methods.has_dependency job
      job.schedular = schedular
    res.json task

  list: (req, res, next) ->
    page = Number(req.param("page")) or 0
    page_count = Number(req.param("page_count")) or 16
    status = req.param("status") or "all"
    status = "all" if status not in ["living", "finished", "all"]
    task_ids = _.uniq(req.data.models.live_jobs.map((job) -> job.get("task_id")))
    filter = {}

    listTasks = ->
      q = req.db.models.task.find(filter)
      switch status
        when "living"
          if task_ids.length is 0
            return res.json {page: page, page_count: page_count, pages: 0, status: status, tasks: []}
          q = q.where("id in (#{task_ids.join(',')})")
        when "finished"
          q = q.where("id not in (#{task_ids.join(',')})") if task_ids.length > 0

      q.count (err, count) ->
        return next(err) if err?
        q.order("-id").offset(page*page_count).limit(page_count).all (err, tasks) ->
          return next(err) if err?
          tasks = JSON.parse(JSON.stringify(tasks))
          delete task.creator.password for task in tasks
          res.json
            page: page
            page_count: page_count
            pages: Math.ceil(count/page_count)
            status: status
            tasks: tasks

    if req.project?
      filter.project_id = req.project.id
      listTasks()
    else
      req.user.getProjects (err, projects) ->
        filter.project_id = _.map(projects, (proj) -> proj.id)
        listTasks()

  remove: (req, res, next) ->
    id = req.task.id
    req.db.models.job.find({task_id: id, status: "started"}).each (job) ->
    req.data.models.live_jobs.forEach (job) ->
      stop_job(job, req.data.models.workstations) if job.get("status") is "started" and job.get("task_id") is id
    req.task.remove (err) ->
      return next(err) if err?
      req.db.models.job.find(task_id: id).remove (err) ->
        return next(err) if err?
        res.send 200
        req.redis.publish "db.task", JSON.stringify(method: "delete", task: id)
        logger.info "Task:#{id} removed."

  cancel: (req, res, next) ->
    id = req.task.id
    req.data.models.live_jobs.forEach (job) ->
      stop_job(job, req.data.models.workstations) if job.get("status") is "started" and job.get("task_id") is id
    req.db.models.job.find({task_id: id, status: ["new", "started"]}).each((job) ->
      job.status = "cancelled"
    ).save (err) ->
      retrieve_task(req, res, next, id)
      req.redis.publish "db.task", JSON.stringify(method: "cancel", task: id)
      logger.info "Task:#{id} cancelled."

  restart: (req, res, next) ->
    id = req.task.id
    req.data.models.live_jobs.forEach (job) ->
      stop_job(job, req.data.models.workstations) if job.get("status") is "started" and job.get("task_id") is id
    req.db.models.job.find({task_id: id}).each((job) ->
      job.status = "new"
    ).save (err) ->
      retrieve_task(req, res, next, id)
      req.redis.publish "db.task", JSON.stringify(method: "restart", task: id)
      logger.info "Task:#{id} re-started."

  add_job: (req, res, next) ->
    job = req.body
    job.task_id = req.task.id
    if not job.repo_url?
      return res.json 500, error: "'repo_url' is mandatory for job."
    job.environ ?= {}
    job.device_filter ?= {}
    job.device_filter.tags ?= []
    job.r_type ?= "none"
    job.r_job_nos ?= []
    job.status = "new"
    job.no = _.max(req.task.jobs, (j) -> j.no).no + 1
    job.priority = req.project.priority
    job.device_filter.tags = _.union(job.device_filter.tags, req.project.tagList())
    job.device_filter.device_owner = req.project.creator.email

    if job.device_filter.tags.length <= 0
      return res.json 500, error: "Job should define at least one tag in 'device_filter.tags'."

    req.db.models.job.create job, (err, j) ->
      return next(err) if err?
      res.json j
      req.redis.publish "db.job", JSON.stringify(method: "add", job: j.id)

  param_job_no: (req, res, next) ->
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
    t_job.priority = req.project.priority
    t_job.device_filter ?= {}
    t_job.device_filter.tags ?= []
    t_job.device_filter.tags = _.union(t_job.device_filter.tags, req.project.tagList())
    t_job.device_filter.device_owner = req.project.creator.email
    t_job.save (err) ->
      return next(err) if err?
      res.json t_job
      req.redis.publish "db.job", JSON.stringify(method: "update", job: t_job.id)
      logger.info "Job:#{t_job.id} updated."

  cancel_job: (req, res, next) ->
    job = req.job
    if job.status in ["cancelled", "finished"]
      return res.json job
    stop_job(req.data.models.live_jobs.get(job.id), req.data.models.workstations)
    job.status = "cancelled"
    job.save (err) ->
      return next(err) if err?
      res.json job
      req.redis.publish "db.job", JSON.stringify(method: "cancel", job: job.id)
      logger.info "Job:#{job.id} cancelled."

  restart_job: (req, res, next) ->
    job = req.job
    if job.status is "new"
      return res.json job
    stop_job(req.data.models.live_jobs.get(job.id), req.data.models.workstations)
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
      ws = req.data.models.workstations.get(dev.workstation_mac)
      if ws?.get("api")?.status is "up"
        url_str = url.format(
          protocol: "http"
          hostname: ws.get("ip")
          port: ws.get("api").port
          pathname: "#{ws.get('api').path}/0/jobs/#{job.id}/stream"
          query: req.query
        )
        stream = request({url: url_str, timeout: 1000*300})
        stream.on("error", (error) ->
          logger.error "**ERROR**: #{error}"
          res.end error.toString()
        ).pipe res
        res.on "close", ->  # client abort
          stream.abort()  # close request to ws
      else
        res.json 404, error: "The workstation is disconnected."

  job_files: (req, res, next) ->
    job = req.job
    if job.status is "new" or not job.device_id
      return res.json 400, error: "No files available."
    req.db.models.device.get job.device_id, (err, dev) ->
      return next(err) if err?
      ws = req.data.models.workstations.get(dev.workstation_mac)
      if ws?.get("api")?.status is "up"
        url_str = url.format(
          protocol: "http"
          hostname: ws.get("ip")
          port: ws.get("api").port
          pathname: "#{ws.get('api').path}/0/jobs/#{job.id}/files/#{req.params[0]}"
          query: req.query
        )
        request(url_str).on('error', (err) ->
          res.end()
        ).pipe res
      else
        res.json 404, error: "The device is disconnected."

  job_screenshot: [
    (req, res, next) ->
      job = req.data.models.jobs.find (job) -> Number(job.id) is req.job.id
      if job?
        req.device = req.data.models.devices.get "#{job.get('workstation').mac}-#{job.get('serial')}"
        next()
      else
        res.json 403, error: "Forbidden on not running job."
    devices.screenshot
  ]

  job_result: (req, res, next) ->
    job = req.job
    if job.status is "new" or not job.device_id
      return res.json 404, error: "Result unavailable."
    req.db.models.device.get job.device_id, (err, dev) ->
      return next(err) if err?
      ws = req.data.models.workstations.get(dev.workstation_mac)
      if ws?.get("api")?.status is "up"
        url_str = url.format(
          protocol: "http"
          hostname: ws.get("ip")
          port: ws.get("api").port
          pathname: "#{ws.get('api').path}/0/jobs/#{job.id}/files/workspace/result.txt"
        )
        stream = request(url_str)
        remaining = ""
        summary = {pass: 0, fail: 0, error: 0, start_at: null, end_at: null, results: []}
        path = "#{req.path[...-6]}files/workspace/"
        filter = (req.param("r") or "pass,fail,error").split(",")

        push_result = (r) ->
          switch r.result.toLowerCase()
            when "pass", "passed", "p"
              summary.pass += 1
              r.result = "pass"
            when "fail", "failed", "failure", "f"
              summary.fail += 1
              r.result = "fail"
            when "error", "e"
              summary.error += 1
              r.result = "error"
          r[t] = new Date r[t] for t in ["start_at", "end_at"]
          summary.start_at = r.start_at if summary.start_at is null or summary.start_at > r.start_at
          summary.end_at = r.end_at if summary.end_at is null or summary.end_at < r.end_at
          if r.result.toLowerCase() in filter
            summary.results.push r
            r[p] = "#{path}#{r[p]}" for p in ["screenshot_at_failure", "expect", "log"] when r[p]?

        parse_line = (line) ->
          try
            push_result JSON.parse(line) if line
          catch error
            logger.error "Error during parsing result: #{error}"
            logger.error "#{line}"

        stream.on "data", (data) ->
          remaining += data
          lines = remaining.split "\n"
          parse_line line for line in lines[...-1]
          remaining = lines[lines.length-1] or ""

        stream.on "error", (err) ->
          next err

        stream.on "end", ->
          parse_line remaining
          summary.total = summary.pass + summary.fail + summary.error
          summary.job = req.job

          page = Number(req.param("page"))
          page_count = Number(req.param("page_count")) or 100

          if page >= 0 and page_count > 0
            summary.page = page
            summary.page_count = page_count
            summary.pages = Math.ceil(summary.results.length / page_count)
            summary.results = summary.results[page*page_count...(page+1)*page_count]
          res.json summary
      else
        res.json 404, error: "The device is disconnected."
