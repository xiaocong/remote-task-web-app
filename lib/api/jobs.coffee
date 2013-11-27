"use strict"

logger = require("../logger")
_ = require("underscore")
tasks = require("./tasks")

module.exports =
  get: (req, res) ->
    res.json req.job

  list: (req, res) ->
    res.json req.zk.models.live_jobs.toJSON()

  cancel: (req, res, next) ->
    job = req.zk.models.live_jobs.get(req.job.id)
    if job?.get("status") in ["new", "started"]
      tasks.kill_job_process(job, req.zk.models.workstations)

      req.job.status = 'cancelled'
      req.job.save (err) ->
        return next(err) if err?
        res.json req.job
        req.redis.publish "db.job", JSON.stringify(method: "cancel", job: req.job.id)
        logger.info "Job:#{req.job.id} cancelled by #{req.user.email}."
    else
      res.json 404, error: "No such a job."
