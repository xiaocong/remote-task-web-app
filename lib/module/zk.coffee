"use strict"

logger = require "../logger"

exports = module.exports = (zk_url, path, db_models, redis, subscriber) ->
  zk = require("./zk_node")(zk_url, path)

  db_collection = require("./db_collection")(db_models)
  device_tags = new db_collection.DeviceTags
  device_tags.fetch()
  new_jobs = new db_collection.NewJobs
  new_jobs.fetch()

  updateDeviceTag = (event) ->
    zk.models.devices.forEach (device) ->
      device.set("tags", device_tags.get(device.id)?.get("tags") or []) 

  zk.models.devices.on 'add', updateDeviceTag
  device_tags.on "change add remove", updateDeviceTag

  subscriber.subscribe "db.device.tag"
  subscriber.subscribe "db.task"
  subscriber.on "message", (channel, message) ->
    logger.info "Received pub-message: #{channel} - #{message}"
    switch channel
      when "db.device.tag" then device_tags.fetch()
      when "db.task", "db.job" then new_jobs.fetch()

  "client": zk.client
  "models":
    "workstations": zk.models.workstations
    "jobs": zk.models.jobs
    "devices": zk.models.devices
    "waiting_jobs": new_jobs
