"use strict"

Backbone = require "backbone"
zookeeper = require "node-zookeeper-client"
_ = require "underscore"
logger = require "../logger"


exports = module.exports = (zookeeper_url, path, cb) ->
  client = zookeeper.createClient zookeeper_url

  workstations = new Backbone.Collection
  jobs = new Backbone.Collection
  devices = new Backbone.Collection

  listChildren = (client, path) ->
    client.getChildren path, (event) ->
      listChildren client, path
    , (error, children, stat) ->
      return logger.error("Failed to list children of #{path} due to: #{error}.") if error
      getChild(client, path, child) for child in children when not workstations.get child

  getChild = (client, path, child) ->
    client.getData "#{path}/#{child}", (event) ->
      switch event.getType()
        when zookeeper.Event.NODE_DELETED
          workstations.remove id: child
          logger.info "Workstation #{child} removed!"
        when zookeeper.Event.NODE_DATA_CHANGED
          getChild client, path, child
          logger.info "Workstation #{child} changed!"
    , (error, data, stat) ->
      return logger.info("Failed to get data of #{path} due to: #{error}.") if error
      ws = JSON.parse data.toString()
      ws.id = child
      logger.info("Workstation #{ws.id} added.") if not workstations.get(child)
      workstations.add [ws], merge: true

  workstations.on "change add remove", (event) ->
    ws_jobs = @filter (ws) ->
      ws.has("api") and ws.get("api").status is "up"
    .map (ws) ->
      _.map ws.get("api").jobs, (job) ->
        "id": job.job_id
        "mac": ws.get "mac"
        "ip": ws.get "ip"
        "uname": ws.get "uname"
        "port": ws.get("api").port
        "job_id": job.job_id
        "started_at": job.started_at
        "exclusive": job.exclusive ? true
        "platform": "android" if job.env.ANDROID_SERIAL?
        "serial": job.env.ANDROID_SERIAL
        "env": job.env
    
    all_jobs = _.flatten(ws_jobs, true)
    jobs.set all_jobs

    ws_devices = @filter (ws) ->
      ws.has("api") and ws.get("api").status is "up"
    .map (ws) ->
      _.map ws.get("api").devices?.android, (device) ->
        "id": "#{ws.get('mac')}-#{device.adb.serial}"
        "workstation":
          "mac": ws.get "mac"
          "ip": ws.get "ip"
          "uname": ws.get "uname"
          "port": ws.get("api").port
        "serial": device.adb.serial
        "platform": "android"
        "product": device.product
        "build": device.build
        "locale": device.locale

    all_devices = _.map _.flatten(ws_devices, true), (device) ->
      device.idle = not _.some(all_jobs, (job) ->
        "#{job.mac}-#{job.serial}" is device.id and job.platform is device.platform and job.exclusive
      )
      device

    devices.set all_devices

  client.once "connected", ->
    logger.info "Connected to ZooKeeper."
    client.mkdirp path, (err) -> # make sure the path is created
      listChildren client, path

    cb(
      "client": client
      "models":
        "workstations": workstations
        "jobs": jobs
        "devices": devices
    )

  client.connect()

