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

  Tag = db.define "tag",
      tag: {type: "text", required: true}
    ,
      validations:
        tag: orm.enforce.unique "Sorry, tag already taken!"

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
    methods:
      tagList: ->
        _.map(@tags, (tag) -> tag.tag)
    autoFetch: true
    cache: false

  Device.hasMany "tags", Tag

  Task = db.define "task",
    name: {type: "text", required: true}
    description: String
  ,
    timestamp: true
    autoFetch: true
    cache: false

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
    cache: false
    validations:
      email: orm.enforce.unique("email already taken!")
    methods:
      compare: (password)->
        bcrypt.compareSync password, @password

  Token = User.extendsTo "token",
    access_token: String
  ,
    timestamp: true

  Task.hasOne "creator", User  # required=true
  Repo.hasOne "creator", User  # required=true

  Job = db.define "job",
    no: {type: "number", required: true}
    environ: {type: "object", required: true}
    device_filter: {type: "object", required: true}  # mac, platform, serial, product, build, locale, tags: [...]
    repo_url: {type: "text", required: true}
    repo_branch: String
    repo_username: String
    repo_passowrd: String
    r_type:
      type: "enum"
      values: ["none", "exclusive", "dependency"]
      defaultValue: "none"
      required: true
    r_job_nos:
      type: "numberArray"
    status:
      type: "enum"
      values: ["new", "started", "finished", "cancelled"]
      defaultValue: "new"
      required: true
    exit_code: Number
  ,
    timestamp: true
    autoFetch: true
    cache: false
    validations:
      no: orm.enforce.unique scope: ["task_id"], "Sorry, serial already taken for this workstation!"

  Job.hasOne "device", Device,
    required: false

  Job.hasOne "task", Task,
    required: true
    reverse: "jobs"

  cb()