"use strict"

logger = require("../logger")
_ = require("underscore")

module.exports =
  get: (req, res) ->
    if req.device?
      res.json req.device.toJSON()
    else
      res.json req.zk.models.devices.toJSON()

  tag_device: (req, res, next) ->
    req.db.models.tag.find tag: req.param("tag"), (err, tags) ->
      return next(err) if err?
      return res.json 500, {error: "No such tag!"} if tags.length is 0
      data = {workstation_mac: req.device.get("workstation").mac, serial: req.device.get("serial")}

      req.db.models.device.find data, (err, devices) ->
        return next(err) if err?

        device = devices[0]
        addTags = ->
          if _.some(device.tags, (t) -> t.tag is tags[0].tag)
            res.json 500, error: "The device already has the tag!"
          else
            device.addTags tags, (err) ->
              return next(err) if err?
              res.send 200
              req.redis.publish "db.device.tag", JSON.stringify(method: "add", device: device.id, tags: tags)

        if device?
          addTags()
        else
          req.db.models.device.create [data], (err, devices) ->
            return next(err) if err?
            device = devices[0]
            addTags()

  untag_device: (req, res, next) ->
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
