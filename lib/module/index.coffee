"use strict"

orm = require("orm")
redis = require("redis")
_ = require("underscore")
config = require("../config")

db = data = redis_client = redis_publish = null
cbs = []

redis_url = require("url").parse config.redis_url
redis_hostname = redis_url.hostname
redis_port = redis_url.port or 6379

require("./db") config.mysql_url, (err, conn) ->
  throw new Error("DB connection exception due to #{err}") if err?

  db = conn
  redis_client = redis.createClient(redis_port, redis_hostname)
  redis_subscribe = redis.createClient(redis_port, redis_hostname)
  require("./data") config.zk_url, config.zk_path, db.models, redis_client, redis_subscribe, (d) ->
    data = d
    cb() for cb in cbs

match = (filter, device) ->
  # filter: mac, platform, serial, product, build, locale, device_owner, tags: [...]
  # "workstation":
  #   "mac": ws.get "mac"
  #   "ip": ws.get "ip"
  #   "port": ws.get("api").port
  # "serial": device.adb.serial
  # "platform": "android"
  # "product": device.product
  # "build": device.build
  # "locale": device.locale
  # "tags": [...]
  keys = ['workstation', 'serial', 'platform', 'product', 'build', 'locale', 'tags']
  return false if _.some(keys, (k) -> not device.get(k)?)
  return false if filter.mac? and device.get("workstation").mac isnt filter.mac
  return false if filter.serial? and device.get("serial") isnt filter.serial
  return false if filter.platform? and device.get("platform") isnt filter.platform
  return false if filter.product? and _.some(filter.product, (v, p) -> v isnt device.get("product")[p])
  return false if filter.locale? and _.some(filter.locale, (v, p) -> v isnt device.get("locale")[p])
  if "build" of filter
    return false if _.some(filter.build, (v, p) -> p isnt "version" and v isnt device.get("build")[p])
    return false if "version" of filter.build and _.some(filter.build.version, (v, p) -> v isnt device.get("build").version[p])
  if filter.device_owner? and device.get('workstation').owner?
    return filter.device_owner is device.get('workstation').owner
  else if filter.tags?  # tags is mandatory for filter, if it's empty, then the match result is always false.
    tags = if filter.tags instanceof Array then filter.tags else [filter.tags]
    device_tags = device.get("tags") or []
    return false if device_tags.length is 0 or _.some(tags, (tag)-> tag not in device_tags)
  return true

has_exclusive = (job) ->
  # return true if any exclusive job is in running or locked status
  if job.r_type isnt "exclusive" or job.r_job_nos.length is 0
    false
  else
    data.models.live_jobs.filter((j) ->
      j.get("task_id") is job.task_id and j.get("no") in job.r_job_nos and j.id isnt job.id
    ).some((j) ->
      j.get("status") is "new" and j.get("locked") or j.get("status") is "started"
    )

has_dependency = (job) ->
  # return true if any dependent job is in running or waiting status
  if job.r_type isnt "dependency" or job.r_job_nos.length is 0
    false
  else
    data.models.live_jobs.some((j) ->
      j.get("task_id") is job.task_id and j.get("no") in job.r_job_nos and j.id isnt job.id
    )

methods =
  match: match
  has_exclusive: has_exclusive
  has_dependency: has_dependency

exports = module.exports =
  setup: ->
    (req, res, next) ->
      req.db = db
      req.redis = redis_client
      req.data = data
      req.methods = methods
      next()

  initialize: (cb) ->
    if db? and data?
      cb()
    else
      cbs.push cb

  db: -> db
  data: -> data
  redis: -> redis.createClient(redis_port, redis_hostname)
  methods: methods
