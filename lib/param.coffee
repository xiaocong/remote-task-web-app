"use strict"

exports.workstation = (req, res, next, id) ->
  ws = req.zk.models.workstations.get(id)
  if ws
    req.workstation = ws
    next()
  else
    next new Error("No specified workstation.")

exports.device = (req, res, next, id) ->
  ws = req.zk.models.deivces.get(id)
  if ws
    req.workstation = ws
    next()
  else
    next new Error("No specified workstation.")

module.exports = exports
