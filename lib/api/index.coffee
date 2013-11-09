"use strict"

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