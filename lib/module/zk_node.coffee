"use strict"

Backbone = require "backbone"
zookeeper = require "node-zookeeper-client"
_ = require "underscore"


exports = module.exports = (zookeeper_url, path) ->
  client = zookeeper.createClient zookeeper_url

  workstations = new Backbone.Collection
  jobs = new Backbone.Collection
  devices = new Backbone.Collection

  listChildren = (client, path) ->
    client.getChildren path, (event) ->
      listChildren client, path
    , (error, children, stat) ->
      return console.log("Failed to list children of #{path} due to: #{error}.") if error
      getChild(client, path, child) for child in children when not workstations.get child

  getChild = (client, path, child) ->
    client.getData "#{path}/#{child}", (event) ->
      switch event.getType()
        when zookeeper.Event.NODE_DELETED
          workstations.remove id: child
          console.log "Workstation #{child} removed!"
        when zookeeper.Event.NODE_DATA_CHANGED
          getChild client, path, child
          console.log "Workstation #{child} changed!"
    , (error, data, stat) ->
      return console.log("Failed to get data of #{path} due to: #{error}.") if error
      ws = JSON.parse data.toString()
      ws.id = child
      console.log("Add workstation #{ws.id}.") if not workstations.get(child)
      workstations.add [ws], merge: true

  workstations.on "change add remove", (event) ->
    ws_jobs = @filter (ws) ->
      ws.has("api") and ws.get("api").status is "up"
    .map (ws) ->
      _.map ws.get("api").jobs, (job) ->
        "id": job.job_id
        "mac": ws.get "mac"
        "ip": ws.get "ip"
        "port": ws.get("api").port
        "job_id": job.job_id
        "timestamp": job.timestamp
        "platform": "android" if job.env.ANDROID_SERIAL?
        "serial": job.env.ANDROID_SERIAL
    
    all_jobs = _.flatten(ws_jobs, true)
    jobs.set all_jobs

    ws_devices = @filter (ws) ->
      ws.has("api") and ws.get("api").status is "up"
    .map (ws) ->
      _.map ws.get("api").devices.android, (device) ->
        "id": "#{ws.get('mac')}-#{device.adb.serial}"
        "workstation":
          "mac": ws.get "mac"
          "ip": ws.get "ip"
          "port": ws.get("api").port
        "serial": device.adb.serial
        "platform": "android"
        "product": device.product
        "build": device.build
        "locale": device.locale

    all_devices = _.map _.flatten(ws_devices, true), (device) ->
      device.idle = not _.some(all_jobs, (job) ->
        "#{job.mac}-#{job.serial}" is device.id and job.platform is device.platform
      )
      device

    devices.set all_devices

  client.once "connected", ->
    console.log "Connected to ZooKeeper."
    listChildren client, path

  client.connect()

  "client": client
  "models":
    "workstations": workstations
    "jobs": jobs
    "devices": devices
