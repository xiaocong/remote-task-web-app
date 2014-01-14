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

exports = module.exports =
  setup: ->
    (req, res, next) ->
      req.db = db
      req.redis = redis_client
      req.data = data
      next()

  initialize: (cb) ->
    if db? and data?
      cb()
    else
      cbs.push cb

  db: -> db
  data: -> data
  redis: -> redis.createClient(redis_port, redis_hostname)

  match: (filter, device) ->
    # filter: mac, platform, serial, product, build, locale, tags: [...]
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
    return false if "mac" of filter and device.get("workstation").mac isnt filter.mac
    return false if "serial" of filter and device.get("serial") isnt filter.serial
    return false if "platform" of filter and device.get("platform") isnt filter.platform
    return false if "product" of filter and _.some(filter.product, (v, p) -> v isnt device.get("product")[p])
    return false if "locale" of filter and _.some(filter.locale, (v, p) -> v isnt device.get("locale")[p])
    if "build" of filter
      return false if _.some(filter.build, (v, p) -> p isnt "version" and v isnt device.get("build")[p])
      return false if "version" of filter.build and _.some(filter.build.version, (v, p) -> v isnt device.get("build").version[p])
    if "tags" of filter  # tags is mandatory for filter, if it's empty, then the match result is always false.
      tags = if filter.tags instanceof Array then filter.tags else [filter.tags]
      device_tags = device.get("tags") or []
      return false if device_tags.length is 0 or _.some(tags, (tag)-> tag not in device_tags)
    return true

