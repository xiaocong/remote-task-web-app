"use strict"

exports.workstation = (req, res, next, id) ->
  ws = req.zk.models.workstations.get(id)
  if ws
    req.workstation = ws
    next()
  else
    res.json 500, error: "No specified workstation."

exports.device = (req, res, next, id) ->
  device = req.zk.models.devices.get(id)
  if device
    req.device = device
    next()
  else
    res.json 500, error: "No specified device."

exports.task = (req, res, next, id) ->
  req.db.models.task.get id, (err, task) ->
    return res.json(500, error: err) if err?
    req.task = task
    next()

exports.job = (req, res, next, id) ->
  req.db.models.job.get id, (err, job) ->
    return res.json(500, error: err) if err?
    req.job = job
    next()

module.exports = exports
