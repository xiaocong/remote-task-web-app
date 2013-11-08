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

module.exports = exports
