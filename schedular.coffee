"use strict"

dbmodule = require("./lib/module")
request = require("request")
url = require("url")
logger = require("./lib/logger")
_ = require("underscore")

dbmodule.initialize ->
  zk = dbmodule.zk()
  db = dbmodule.db()
  redis = dbmodule.redis()

  devices = zk.models.devices
  live_jobs = zk.models.live_jobs
  zk_jobs = zk.models.jobs

  schedule = ->
    live_jobs.forEach (job) -> logger.info "Job #{job.id}: status=#{job.get('status')}, locked=#{job.get('locked')}"
    devices.forEach (device) -> logger.info "Device #{device.id}: idle=#{device.get('idle')}, locked=#{device.get('locked')}"
    live_jobs.filter((job) -> job.get("status") is "new" and not job.get("locked")).forEach (job) ->
      if has_exclusive(job) or has_dependency(job)
        logger.info "Job #{job.id} has #{job.get('r_type')} on #{JSON.stringify(job.get("r_job_nos"))}."
      else
        filter = job.get("device_filter") or {}
        devices.filter((dev) -> dev.get("idle") and not dev.get("locked")).some (device) ->
          if match(filter, device)
            logger.info "Assigning Job #{job.id} to device #{device.id}."
            assign_task(device, job) 
            return true
          false

  has_exclusive = (job) ->
    # return true if any exclusive job is in running or locked status
    if job.get("r_type") isnt "exclusive" or job.get("r_job_nos").length is 0
      false
    else
      live_jobs.filter((j) ->
        j.get("task_id") is job.get("task_id") and j.get("no") in job.get("r_job_nos")
      ).some((j) ->
        j.get("status") is "new" and j.get("locked") or j.get("status") is "started"
      )

  has_dependency = (job) ->
    # return true if any dependent job is in running or waiting status
    if job.get("r_type") isnt "dependency" or job.get("r_job_nos").length is 0
      false
    else
      live_jobs.some((j) ->
        j.get("task_id") is job.get("task_id") and j.get("no") in job.get("r_job_nos")
      )

  match = (filter, device) ->
    # filter: mac, platform, serial, product, build, locale, tags: [...]
    # "workstation":
    #   "mac": ws.get "mac"
    #   "ip": ws.get "ip"
    #   "port": ws.get("api").port
    # "serial": device.adb.serial
    # "platform": "android"
    # "product": device.product
    # "build": device.build
    # "locale": device.locale
    # "tags": [...]
    return false if "mac" of filter and device.get("workstation").mac isnt filter.mac
    return false if "serial" of filter and device.get("serial") isnt filter.serial
    return false if "platform" of filter and device.get("platform") isnt filter.platform
    return false if "product" of filter and _.some((p for p of filter.product), (p) -> filter.product[p] isnt device.get("product")[p])
    return false if "locale" of filter and _.some((p for p of filter.locale), (p) -> filter.locale[p] isnt device.get("locale")[p])
    if "build" of filter
      return false if _.some((p for p of filter.build when p isnt "version"), (p) -> filter.build[p] isnt device.get("build")[p])
      return false if "version" of filter.build and _.some((p for p of filter.build.version), (p) -> filter.build.version[p] isnt device.get("build").version[p])
    if "tags" of filter  # tags is mandatory for filter, if it's empty, then the match result is always false.
      tags = if filter.tags instanceof Array then filter.tags else [filter.tags]
      return false if _.some(tags, (tag)-> tag not in (device.get("tags") or []))
    return true    

  assign_task = (device, job) ->
    job.set {locked: true}, {silent: true}
    device.set {locked: true}, {silent: true}
    url_str = url.format(
      protocol: "http"
      hostname: device.get("workstation").ip
      port: device.get("workstation").port
      pathname: "/api/0/jobs/#{job.id}"
    )
    body =
      env: job.get("environ")
      repo:
        url: job.get("repo_url")
    body.repo.branch = job.get("repo_branch") if job.has("repo_branch")
    body.repo.username = job.get("repo_username") if job.has("repo_username")
    body.repo.password = job.get("repo_passowrd") if job.has("repo_passowrd")
    body.env["ANDROID_SERIAL"] = device.get("serial")
    body.env["TASK_ID"] = job.get("task_id")
    body.env["JOB_NO"] = job.get("no")
    request.post {url: url_str, json: body}, (err, res, body) ->
      if err? or res.statusCode isnt 200
        logger.error "Error response: #{body}"
        logger.error "Error when assigning job #{job.id} to device #{device.id}"
        job.set {locked: false}, {silent: true}
        device.set {locked: false}
      else
        db.models.device.find {workstation_mac: device.get("workstation").mac, serial: device.get("serial")}, (err, devices) ->
          db.models.job.get job.id, (err, job) ->
            job.device_id = devices[0].id
            job.status = "started"
            job.save (err) ->
              logger.info "Job #{job.id} was saved as started."
              redis.publish "db.job", JSON.stringify({method: "started", job: job.id})

  finish_job = (event) ->
    id = event.id
    hostname = event.get("ip")
    port = event.get("port")
    logger.info "Job #{id} finished."

    db.models.job.find({id: id, status: "started"}).each((job) -> # to avoid user cancels or restarts job.
      job.status = "finished"
    ).save (err) ->
      return logger.error("Error during saving job as finished: #{err}") if err?
      redis.publish "db.job", JSON.stringify({method: "finished", job: id})
      url_str = url.format(
        protocol: "http"
        hostname: hostname
        port: port
        pathname: "/api/0/jobs/#{id}"
      )
      request.get url_str, (err, r, b) ->
        return logger.error("Error when retrieving job result from workstation: #{err}") if err?
        db.models.job.get id, (err, job) ->
          job.exit_code = JSON.parse(b).exit_code
          job.save((err) -> logger.error "DB error: #{err}" if err)

  devices.on "change:idle", (event) ->
    devices.filter((device) -> not device.get("idle") and device.get("locked")).forEach (device) ->
      device.set {locked: false}
      logger.info "Device #{device.id} unlocked due to busy."
  devices.on "change add", schedule
  live_jobs.on "change add remove", schedule
  zk_jobs.on "remove", finish_job

  schedule()
