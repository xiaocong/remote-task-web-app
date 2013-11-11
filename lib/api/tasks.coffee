"use strict"

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
      job["device_filter"] ?= {}
      job["r_type"] ?= "none"
      job["r_job_nos"] ?= []
      job["status"] = "new"
      job["no"] ?= index

    req.db.transaction (err, t) ->
      req.db.models.task.create [{name: name, description: description, creator_id: req.user.id}], (err, tasks) ->
        if err?
          t.rollback((err)->)
          return res.json 500, error: "DB transaction error!"
        job.task_id = tasks[0].id for job in jobs
        req.db.models.job.create jobs, (err, jobs) ->
          t.commit (err)->
            if err?
              t.rollback((err)->)
              return res.json 500, error: "DB transaction error!"
            else
              tasks[0].jobs = jobs
              res.json tasks[0]
              req.redis.publish "db.task", JSON.stringify(method: "add", task: tasks[0].id)

  get: (req, res, next) ->
    id = req.params.id
    req.db.models.task.get id, (err, task) ->
      return next(err) if err?
      res.json task
