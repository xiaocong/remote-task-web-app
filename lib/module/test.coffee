"use strict"

database = require './db'
_ = require "underscore"

database 'mysql://test:12345@localhost/remote_task?debug=true', (err, db) ->
  throw err if err

  DeviceTag = db.models.tag
  Workstation = db.models.workstation
  Device = db.models.device
  Task = db.models.task
  Repo = db.models.repo
  User = db.models.user
  Job = db.models.job

  db.models.user.create [{name: 'test', email: 'test@borqs.com'}], (err, items) ->
    return if err
    console.log "Name: #{item.name}, Email: #{item.email}" for item in items
  db.models.user.find name: 'test', (err, users) ->
    console.log "#{user.email}" for user in users
  db.models.tag.find (err, tags) ->
    if tags.length is 0
      db.models.tag.create [{name: 'job_type', value: 'device_test'}, {name: 'job_type', value: 'app_test'}], (err, tags) ->
        if err
          console.log err
          return err
        console.log "#{tag.name}: #{tag.value}" for tag in tags
  db.models.device.find (err, devices) ->
    if devices.length is 0
      db.models.device.create [{workstation_mac: '84:4b:f5:8a:a8:8f', serial: 'Medfield19032CF2'}, {workstation_mac: '00:26:b9:e7:a2:3b', serial: 'Medfield19032CF2'}], (err, devices) ->
        console.log "#{device}" for device in devices
        for device in devices
          do (device=device) ->
            db.models.tag.find value: 'device_test', (err, tags) ->
              device.setTags tags, (err) ->
                console.log err if err
                device.getTags (err, tags) -> console.log "#{tags}" if tags

  zk = require('./zk_node')('localhost:2181', '/remote/alive/workstation')
  devices = zk.models.devices
  jobs = zk.models.jobs
  workstations = zk.models.workstations

  models = require("./db_collection")(db.models)
  device_tags = new models.DeviceTags
  device_tags.fetch()

  updateDeviceTag = (event) ->
    device_tags.forEach (tag) ->
      zk.models.devices.get(tag.id)?.set("tags", tag.get("tags"))

  zk.models.devices.on 'add', updateDeviceTag

  device_tags.on "change add remove", updateDeviceTag

  zk.models.devices.on 'remove', (event) ->
    console.log "#{event.id} got removed!"

  zk.models.devices.on 'change:idle', (event) ->
    zk.models.devices.forEach (d) -> console.log "#{d.id}: #{if d.get("idle") then 'idle' else 'busy'}"


  new_jobs = new models.NewJobs
  new_jobs.fetch()
  new_jobs.on "change add remove", (event) ->
    console.log "#{JSON.stringify(new_jobs)}"
