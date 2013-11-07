"use strict"

exports.awesomeThings = (req, res) ->
  res.json [
    "HTML5 Boilerplate"
    "AngularJS"
    "Karma"
    "Express"
  ]

exports.devices = (req, res) ->
    console.log req.zk.models.devices
    res.json req.zk.models.devices.toJSON()