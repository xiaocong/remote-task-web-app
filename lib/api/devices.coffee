logger = require("../logger")
_ = require("underscore")

module.exports =
  get: (req, res) ->
    if req.device?
      res.json req.device.toJSON()
    else
      res.json req.zk.models.devices.toJSON()

  tag_device: (req, res) ->
    req.db.models.device_tag.find {name: req.params.tag_name, value: req.params.tag_value}, (err, tags) ->
      throw err if err?
      return res.json 500, {error: "No such tag!"} if tags.length is 0
      data = {workstation_mac: req.device.get("workstation").mac, serial: req.device.get("serial")}

      req.db.models.device.find data, (err, devices) ->
        throw err if err?

        device = devices[0]
        addTags = ->
          if _.some(device.tags, (t) -> t.id is tags[0].id)
            res.json 500, error: "The device already has the tag!"
          else
            device.addTags tags, (err) ->
              throw err if err?
              res.send 200
              req.redis.publish "db.device_tag", JSON.stringify(method: "add", device: device.id, tags: tags)

        if device?
          addTags()
        else
          req.db.models.device.create [data], (err, devices) ->
            throw err if err?
            device = devices[0]
            addTags()

  untag_device: (req, res) ->
    req.db.models.device_tag.find {name: req.params.tag_name, value: req.params.tag_value}, (err, tags) ->
      throw err if err?

      data = {workstation_mac: req.device.get("workstation").mac, serial: req.device.get("serial")}
      req.db.models.device.find data, (err, devices) ->
        throw err if err?

        device = devices[0]
        if device?
          device.removeTags tags, (err) ->
            throw err if err?
            res.send 200
            req.redis.publish "db.device_tag", JSON.stringify(method: "delete", device: device.id, tags: tags)
        else
          res.send 200
