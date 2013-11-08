"use strict"

request = require("request")
url = require("url")
_ = require("underscore")

exports.awesomeThings = (req, res) ->
  res.json [
    "HTML5 Boilerplate"
    "AngularJS"
    "Karma"
    "Express"
  ]

exports.devices = (req, res) ->
  if req.device?
    res.json req.device.toJSON()
  else
    res.json req.zk.models.devices.toJSON()

exports.tag_device = (req, res) ->
  req.db.models.device_tag.find {name: req.params.tag_name, value: req.params.tag_value}, (err, tags) ->
    return res.json 500, {error: "Error due to #{err}!"} if err?
    return res.json 500, {error: "No such tag!"} if tags.length is 0
    data = {workstation_mac: req.device.get("workstation").mac, serial: req.device.get("serial")}
    req.db.models.device.find data, (err, devices) ->
      return res.json 500, {error: "Error due to #{err}!"} if err?

      device = devices[0]
      addTags = ->
        if _.some(device.tags, (t) -> t.id is tags[0].id)
          res.json 500, error: "The device already has the tag!"
        else
          device.addTags tags, (err) ->
            if err?
              res.json 500, error: "Error due to #{err}!"
            else
              res.send 200
              req.redis.publish "db.device_tag", JSON.stringify(method: "add", device: device.id, tags: tags)

      if device
        addTags()
      else
        req.db.models.device.create [data], (err, devices) ->
          return res.json(500, error: "Error due to #{err}!") if err?
          device = devices[0]
          addTags()

exports.untag_device = (req, res) ->
  req.db.models.device_tag.find {name: req.params.tag_name, value: req.params.tag_value}, (err, tags) ->
    return res.json 500, {error: "Error due to #{err}!"} if err?

    data = {workstation_mac: req.device.get("workstation").mac, serial: req.device.get("serial")}
    req.db.models.device.find data, (err, devices) ->
      return res.json 500, {error: "Error due to #{err}!"} if err?

      device = devices[0]
      if device?
        device.removeTags tags, (err) ->
          if err?
            res.json 500, error: "Error due to #{err}."
          else
            res.send 200
            req.redis.publish "db.device_tag", JSON.stringify(method: "delete", device: device.id, tags: tags)
      else
        res.send 200

exports.workstations = (req, res) ->
  if req.workstation?
    res.json req.workstation.toJSON()
  else
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

exports.tags = (req, res) ->
  req.db.models.device_tag.find (err, tags) ->
    result = {}
    result[name] = _.map(objs, (tag)->tag.value) for name, objs of _.groupBy(tags, (tag) -> tag.name)
    if req.params.tag_name?
      res.json(result[req.params.tag_name] or [])
    else
      res.json result

exports.tags_create = (req, res) ->
  req.db.models.device_tag.create [{name: req.params.tag_name, value: req.params.tag_value}], (err, tags) ->
    if err?
      res.json 500, {error: "Internal error due to #{err}"}
    else
      res.send 200
