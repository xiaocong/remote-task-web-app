"use strict"

request = require("request")
url = require("url")
logger = require("../logger")
_ = require("underscore")

module.exports =
  get: (req, res) ->
    device = req.device.toJSON()
    device.jobs = req.data.models.live_jobs.filter (job) -> job.get("status") is "started" and "#{job.get('device').workstation_mac}-#{job.get('device').serial}" is device.id
    res.json device

  list: (req, res) ->
    devices = req.data.models.devices.toJSON()
    devices.forEach (device) ->
      device.jobs = req.data.models.live_jobs.filter (job) -> job.get("status") is "started" and "#{job.get('device').workstation_mac}-#{job.get('device').serial}" is device.id
    res.json devices

  tag_device: (req, res, next) ->
    req.db.models.tag.find tag: req.param("tag"), (err, tags) ->
      return next(err) if err?
      return res.json 500, {error: "No such tag!"} if tags.length is 0
      data = {workstation_mac: req.device.get("workstation").mac, serial: req.device.get("serial")}

      req.db.models.device.find data, (err, devices) ->
        return next(err) if err or devices.length is 0

        device = devices[0]
        if _.some(device.tags, (t) -> t.tag is tags[0].tag)
          res.json 500, error: "The device already has the tag!"
        else
          device.addTags tags, (err) ->
            return next(err) if err?
            res.send 200
            req.redis.publish "db.device.tag", JSON.stringify(method: "add", device: device.id, tags: tags)


  untag_device: (req, res, next) ->
    if "system:role:admin" is req.param("tag")
      return res.json 400, error: "The tag can not be removed."
    req.db.models.tag.find tag: req.param("tag"), (err, tags) ->
      return next(err) if err?

      data = {workstation_mac: req.device.get("workstation").mac, serial: req.device.get("serial")}
      req.db.models.device.find data, (err, devices) ->
        return next(err) if err?

        device = devices[0]
        if device?
          device.removeTags tags, (err) ->
            return next(err) if err?
            res.send 200
            req.redis.publish "db.device.tag", JSON.stringify(method: "delete", device: device.id, tags: tags)
        else
          res.send 200

  screenshot: (req, res) ->
    ws = req.device.get("workstation")
    url_str = url.format(
      protocol: "http"
      hostname: ws.ip
      port: ws.port
      pathname: "#{ws.path}/0/devices/#{req.device.get('serial')}/screenshot"
      query: req.query
    )
    req.pipe(request(url_str)).on('error', (err) ->
      res.end()
    ).pipe res
