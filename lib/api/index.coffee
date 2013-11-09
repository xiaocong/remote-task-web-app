"use strict"

logger = require("../logger")

exports.awesomeThings = (req, res) ->
  res.json [
    "HTML5 Boilerplate"
    "AngularJS"
    "Karma"
    "Express"
  ]

exports.admin_auth = (req, res, next) ->
  logger.info "only admin can access the api"
  next()  # TODO

exports.devices = require("./devices")
exports.workstations = require("./workstations")
exports.tags = require("./tags")