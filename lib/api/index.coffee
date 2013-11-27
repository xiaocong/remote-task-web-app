"use strict"

logger = require("../logger")

exports.awesomeThings = (req, res) ->
  res.json [
    "HTML5 Boilerplate"
    "AngularJS"
    "Karma"
    "Express"
  ]

exports.devices = require("./devices")
exports.workstations = require("./workstations")
exports.tags = require("./tags")
exports.auth = require("./auth")
exports.account = require("./account")
exports.users = require("./users")
exports.tasks = require("./tasks")
exports.projects = require("./projects")
exports.jobs = require("./jobs")
