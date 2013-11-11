"use strict"

exports = module.exports = (zk_url, path, db_models, redis, subscriber) ->
  zk = require("./zk_node")(zk_url, path)

  db_collection = require("./db_collection")(db_models)
  device_tags = new db_collection.DeviceTags
  device_tags.fetch()

  updateDeviceTag = (event) ->
    zk.models.devices.forEach (device) ->
      device.set("tags", device_tags.get(device.id)?.get("tags") or []) 

  zk.models.devices.on 'add', updateDeviceTag
  device_tags.on "change add remove", updateDeviceTag

  subscriber.subscribe "db.device.tag"
  subscriber.on "message", (channel, message) ->
    device_tags.fetch()

  "client": zk.client
  "models":
    "workstations": zk.models.workstations
    "jobs": zk.models.jobs
    "devices": zk.models.devices
