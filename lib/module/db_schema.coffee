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
      if Array.isArray(value)
        value
      else if value is null or value.length is 0
        []
      else
        value.split(',').map((v) -> Number(v))
    propertyToValue: (value, prop) -> value.join(',')

  db.defineType "stringArray",
    datastoreType: (prop) -> "TEXT"
    valueToProperty: (value, prop) ->
      if Array.isArray(value)
        value
      else if value is null or value.length is 0
        []
      else
        value.split(',')
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
      getDeviceID: ->
        "#{@workstation_mac}-#{@serial}"
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
    priority: {type: "number", rational: false, required: true, defaultValue: 1}
    tags:
      type: "stringArray"
  ,
    timestamp: true
    cache: false
    validations:
      email: [orm.enforce.unique("email already taken!"), orm.enforce.security.username(expr: ///^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$///)]
      priority: orm.enforce.ranges.number(1, 10)
    methods:
      compare: (password) ->
        bcrypt.compareSync password, @password
    hooks:
      beforeSave: (next) ->
        @tags = _.uniq @tags
        next()

  Project = db.define "project",
    name: {type: "text", required: true}
    priority: {type: "number", rational: false, required: true, defaultValue: 1}
  ,
    timestamp: true
    cache: false
    autoFetch: true
    validations:
      priority: orm.enforce.ranges.number(1, 10)
      name: orm.enforce.unique scope: ["creator_id"], "Sorry, name already taken for the user!"
    methods:
      tagList: ->
        _.map(@tags, (tag) -> tag.tag)

  Project.hasOne "creator", User
  Project.hasMany "users", User, {owner: Boolean}, reverse: "projects"
  Project.hasMany "tags", Tag
  Task.hasOne "project", Project,
    required: true

  Token = User.extendsTo "token",
    access_token: String
  ,
    timestamp: true

  Task.hasOne "creator", User  # required=true
  Repo.hasOne "creator", User  # required=true

  Job = db.define "job",
    no: {type: "number", rational: false, required: true}
    environ: {type: "object", required: true}
    device_filter: {type: "object", required: true}  # mac, platform, serial, product, build, locale, tags: [...]
    repo_url: {type: "text", required: true}
    repo_branch: String
    repo_username: String
    repo_passowrd: String
    priority: {type: "number", rational: false, required: true, defaultValue: 1}
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
      no: orm.enforce.unique scope: ["task_id"]
      priority: orm.enforce.ranges.number(1, 10)

  Job.hasOne "device", Device,
    required: false

  Job.hasOne "task", Task,
    required: true
    reverse: "jobs"

  cb()