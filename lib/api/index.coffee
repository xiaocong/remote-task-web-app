"use strict"

request = require("request")
url = require("url")

exports.awesomeThings = (req, res) ->
  res.json [
    "HTML5 Boilerplate"
    "AngularJS"
    "Karma"
    "Express"
  ]

exports.devices = (req, res) ->
  res.json req.zk.models.devices.toJSON()

exports.workstations = (req, res) ->
  res.json req.zk.models.workstations.toJSON()

exports.workstation_api = (req, res) ->
  ws = req.zk.models.workstations.get(req.params[0])
  if ws?.get("api")?.status is "up"
    url_str = url.format(
      protocol: "http"
      hostname: ws.get("ip")
      port: ws.get("api").port
      pathname: "#{ws.get("api").path}/#{req.params[1]}"
      query: req.query
    )
    req.pipe(request(url_str)).pipe(res)
  else
    res.json 500, error: "The workstation is invalid or down!"
