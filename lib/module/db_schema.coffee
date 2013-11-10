"use strict"

orm = require "orm"
modts = require 'orm-timestamps'
transaction = require 'orm-transaction'
_ = require "underscore"
bcrypt = require 'bcrypt'

exports = module.exports = (db, cb) ->
  db.use transaction
  db.use modts,
    createdProperty: "created_at"
    modifiedProperty: "modified_at"
    dbtype: {type: "date", time: true}
    now: () -> new Date

  db.defineType "numberArray",
    datastoreType: (prop) -> "TEXT"
    valueToProperty: (value, prop) ->
      if Array.isArray(value) then value else value.split(',').map((v) -> Number(v))
    propertyToValue: (value, prop) -> value.join(',')

  DeviceTag = db.define "device_tag",
      name: {type: "enum", values: ["job_type"], required: true}
      value: {type: "text", required: true}
    , validations:
        value: orm.enforce.unique scope: ["name"], "Sorry, value already taken for this name!"

  Workstation = db.define "workstation",
    mac: String
    name: {type: "text", required: true}
  , id: "mac"

  Device = db.define "device",
    workstation_mac: {type: "text", required: true}  # workstations are updated in zk, and unnamed workstations are not in db, so here we don't use workstation_id
    serial: {type: "text", required: true}
  ,
    validations:

      
      serial: orm.enforce.unique scope: ["workstation_mac"], "Sorry, serial already taken for this workstation!"
    autoFetch: true
    cache: false
    methods:
      getNamedTags: (name="job_type") ->
        _.map(_.filter(@.tags, (tag) -> tag.name is name), (tag) -> tag.value)
      getTagNames: ->
        name for name of _.groupBy(@tags, (tag) -> tag.name)

  Device.hasMany "tags", DeviceTag, {comments: String}, {reverse: "devices"}

  Task = db.define "task",
    name: {type: "text", required: true}
    description: String
  ,
    timestamp: true

  Repo = db.define "repo",
    url: {type: "text", required: true}
    branch: {type: "text"}
    username: {type: "text"}
    password: {type: "text"}

  User = db.define "user",
    email: {type: "text", required: true}
    password: {type: "text", required: true}
    name: String
  ,
    timestamp: true
    validations:
      email: orm.enforce.unique("email already taken!")
    methods:
      compare: (password)->
        bcrypt.compareSync password, @password

  Task.hasOne "creator", User  # required=true
  Repo.hasOne "creator", User  # required=true

  Token = User.extendsTo "token",
    access_token: String
  ,
    timestamp: true

  Job = db.define "job",
    no: {type: "number", required: true}
    environ: {type: "object", defaultValue: {}}
    device_filter: {type: "object", required: true}  # mac, platform, serial, product, build, locale, tags: {"job_type": '......'}
    status:
      type: "enum"
      values: ["new", "started", "finished"]
      defaultValue: "new"
      required: true
    r_type:
      type: "enum"
      values: ["none", "exclusive", "dependency"]
      defaultValue: "none"
      required: true
    r_job_nos:
      type: "numberArray"
    exit_code: Number
  ,
    timestamp: true
    autoFetch: true
    autoSave: true
    validations:
      no: orm.enforce.unique scope: ["task_id"], "Sorry, serial already taken for this workstation!"

  Job.hasOne "device", Device,
    required: false

  Job.hasOne "task", Task,
    required: true
    reverse: "jobs"

  Job.hasOne "repo", Repo,
    required: true

  cb()