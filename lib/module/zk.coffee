"use strict"

exports = module.exports = (zk_url, path, db_models, redis) ->
  zk = require("./zk_node")(zk_url, path)

  db_collection = require("./db_collection")(db_models)
  device_tags = new db_collection.DeviceTags
  device_tags.fetch()

  updateDeviceTag = (event) ->
    device_tags.forEach (tag) ->
      device = zk.models.devices.get tag.id
      device?.set("tags", tag.get("tags"))

  zk.models.devices.on 'add', updateDeviceTag
  device_tags.on "change add remove", updateDeviceTag

  "client": zk.client
  "models":
    "workstations": zk.models.workstations
    "jobs": zk.models.jobs
    "devices": zk.models.devices
