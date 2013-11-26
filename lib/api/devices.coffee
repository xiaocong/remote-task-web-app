"use strict"

logger = require("../logger")
_ = require("underscore")
tasks = require("./tasks")

module.exports =
  get: (req, res) ->
    device = req.device.toJSON()
    device.jobs = req.zk.models.live_jobs.filter (job) -> job.get("status") is "started" and "#{job.get('device').workstation_mac}-#{job.get('device').serial}" is device.id
    res.json device

  list: (req, res) ->
    devices = req.zk.models.devices.toJSON()
    devices.forEach (device) ->
      device.jobs = req.zk.models.live_jobs.filter (job) -> job.get("status") is "started" and "#{job.get('device').workstation_mac}-#{job.get('device').serial}" is device.id
    res.json devices

  tag_device: (req, res, next) ->
    req.db.models.tag.find tag: req.param("tag"), (err, tags) ->
      return next(err) if err?
      return res.json 500, {error: "No such tag!"} if tags.length is 0
      data = {workstation_mac: req.device.get("workstation").mac, serial: req.device.get("serial")}

      req.db.models.device.find data, (err, devices) ->
        return next(err) if err?

        device = devices[0]
        addTags = ->
          if _.some(device.tags, (t) -> t.tag is tags[0].tag)
            res.json 500, error: "The device already has the tag!"
          else
            device.addTags tags, (err) ->
              return next(err) if err?
              res.send 200
              req.redis.publish "db.device.tag", JSON.stringify(method: "add", device: device.id, tags: tags)

        if device?
          addTags()
        else
          req.db.models.device.create [data], (err, devices) ->
            return next(err) if err?
            device = devices[0]
            addTags()

  untag_device: (req, res, next) ->
    if "system:role:admin" is req.param("tag")
      return res.json 400, error: "The tag can not be removed."
    req.db.models.tag.find tag: req.param("tag"), (err, tags) ->
      return next(err) if err?

      data = {workstation_mac: req.device.get("workstation").mac, serial: req.device.get("serial")}
      req.db.models.device.find data, (err, devices) ->
        return next(err) if err?

        device = devices[0]
        if device?
          device.removeTags tags, (err) ->
            return next(err) if err?
            res.send 200
            req.redis.publish "db.device.tag", JSON.stringify(method: "delete", device: device.id, tags: tags)
        else
          res.send 200

  cancel_job: (req, res, next) ->
    job = req.zk.models.live_jobs.get(Number(req.param("job")))
    if job?.get("status") is "started" and job.get("device").workstation_mac is req.device.get("workstation").mac
      tasks.kill_job_process(job, req.zk.models.workstations)
      req.db.models.job.get job.id, (err, job) ->
        return next(err) if err?
        job.status = 'cancelled'
        job.save (err) ->
          return next(err) if err?
          res.json job
          req.redis.publish "db.job", JSON.stringify(method: "cancel", job: job.id)
          logger.info "Job:#{job.id} cancelled by #{req.user.email}."
    else
      res.json 404, error: "No such a job."
