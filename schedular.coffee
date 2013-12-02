"use strict"

dbmodule = require("./lib/module")
request = require("request")
url = require("url")
logger = require("./lib/logger")
_ = require("underscore")
Backbone = require ("backbone")

dbmodule.initialize ->
  zk = dbmodule.zk()
  db = dbmodule.db()
  redis = dbmodule.redis()

  devices = zk.models.devices
  live_jobs = zk.models.live_jobs
  zk_jobs = zk.models.jobs
  events = _.extend {}, Backbone.Events

  schedule_count = 0
  schedule = ->
    # urgly. We want not to schedule for every "remove" event, so add 5 seconds delay.
    schedule_count += 1
    setTimeout arrange, 5000 if schedule_count is 1

  arrange = ->
    schedule_count = 0
    live_jobs.forEach (job) -> logger.debug "Job #{job.id}: status=#{job.get('status')}, locked=#{job.get('locked')}"
    devices.forEach (device) -> logger.debug "Device #{device.id}: idle=#{device.get('idle')}, locked=#{device.get('locked')}"
    [10..1].forEach (priority) -> live_jobs.filter((job) -> job.get("priority") is priority and job.get("status") is "new" and not job.get("locked")).forEach (job) ->
      if has_exclusive(job) or has_dependency(job)
        logger.debug "Job #{job.id} has #{job.get('r_type')} on #{JSON.stringify(job.get("r_job_nos"))}."
      else
        filter = job.get("device_filter") or {}
        device = devices.find (dev) ->
          dev.get("idle") and not dev.get("locked") and match(filter, dev)
        assign_task(device, job) if device?

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
    return false if "product" of filter and _.some(filter.product, (v, p) -> v isnt device.get("product")[p])
    return false if "locale" of filter and _.some(filter.locale, (v, p) -> v isnt device.get("locale")[p])
    if "build" of filter
      return false if _.some(filter.build, (v, p) -> p isnt "version" and v isnt device.get("build")[p])
      return false if "version" of filter.build and _.some(filter.build.version, (v, p) -> v isnt device.get("build").version[p])
    if "tags" of filter  # tags is mandatory for filter, if it's empty, then the match result is always false.
      tags = if filter.tags instanceof Array then filter.tags else [filter.tags]
      device_tags = device.get("tags") or []
      return false if device_tags.length is 0 or _.some(tags, (tag)-> tag not in device_tags)
    return true    

  assign_task = (device, job) ->
    logger.info "Assigning job #{job.id} to device #{device.id}."
    job.set {locked: true, assigned_device: device.id}, {silent: true}
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
        logger.error "Error when assigning job #{job.id} to device #{device.id}, response is #{body}"
        job.unset "locked", silent: true # triggered by device change next step, so silent for job change.
        job.unset "assigned_device", silent: true
        device.unset "locked"
      else
        db.models.device.find {workstation_mac: device.get("workstation").mac, serial: device.get("serial")}, (err, devices) ->
          events.trigger("update:job", {
            find:
              id: job.id
              status: "new"
            update:
              device: devices[0]
              status: "started"
          }) if devices?.length > 0

  finish_job = (event) ->
    id = event.id
    hostname = event.get("ip")
    port = event.get("port")
    logger.info "Job #{id} finished."

    events.trigger("update:job",
      find:{id: id, status: "started"}
      update: {status: "finished"}
      callback: (err) ->
        return logger.error("Error during saving job as finished: #{err}") if err?
        url_str = url.format(
          protocol: "http"
          hostname: hostname
          port: port
          pathname: "/api/0/jobs/#{id}"
        )
        request.get url_str, (err, r, b) ->
          return logger.error("Error when retrieving job result from workstation: #{err}") if err?
          events.trigger "update:job", {find:{id: id}, update: {exit_code: JSON.parse(b).exit_code}}
    )

  devices.on "add", (device) ->
    db.models.device.create {workstation_mac: device.get("workstation").mac, serial: device.get("serial")}, (err, device) ->
      return if err?
      db.models.tag.find (err, tags) ->
        return if err?
        default_tags = ["system:role:admin"]
        device.addTags _.filter(tags, (t) -> t.tag in default_tags), (err) ->
          return if err?
          redis.publish "db.device.tag", JSON.stringify(method: "add", device: device.id, tags: default_tags)
  devices.on "change add", (device) -> # when there is an unlocked and idle device, we should schedule.
    schedule() if device.get("idle") and not device.get("locked")

  live_jobs.on "change add", (job) -> # when there is an unlocked and new job, we should schedule.
    schedule() if job.get("status") is "new" and not job.get("locked")
  live_jobs.on "remove", (job) ->
    devices.get(job.get("assigned_device"))?.unset("locked", {silent: true}) if job.has("assigned_device")
    schedule()  # when a running removed, some dependent/exclusive jobs need to be scheduled.
  live_jobs.on "change:status", (job) -> # unset locked in case of job status change due to started or restart
    if job.get("status") is "new"
      if job.has("assigned_device")
        devices.get(job.get("assigned_device"))?.unset("locked")
        job.unset("assigned_device", silent: true)
      job.unset("locked")

  zk_jobs.on "remove", finish_job

  zk_jobs.on "add", (job) ->
    # Due to async issue, job precess may be running but the job status in db is not started.
    if not live_jobs.get(job.id) or (live_jobs.get(job.id).get("status") is "new" and not live_jobs.get(job.id).get("locked"))
      url_str = url.format(
        protocol: "http"
        hostname: job.get("ip")
        port: job.get("port")
        pathname: "/api/0/jobs/#{job.id}/stop"
      )
      request.get url_str, (err, r, b) ->
      logger.warn "Kill untracked job: #{job.id}"

  events.on "update:job", (msg) ->
    logger.debug "Find jobs #{JSON.stringify(msg.find)} and update to #{JSON.stringify(msg.update)}"
    db.models.job.find(msg.find).each((job) ->
      _.each msg.update, (v, p)-> job[p] = v
    ).save (err) ->
      return msg.callback?(err) if err?
      redis.publish "db.job", JSON.stringify({find: msg.find, update: msg.update})
      msg.callback?()

  setInterval schedule, 60*1000
