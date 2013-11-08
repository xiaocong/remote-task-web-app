"use strict"

orm = require "orm"
redis = require("redis")

db = zk = redis_client = null
nexts = []

exports.setup = (app) ->
  return if db?

  mysql_url = app.get "mysql_url"
  zk_url = app.get "zk_url"
  zk_path = app.get "zk_path"
  redis_url = require("url").parse app.get("redis_url")
  redis_hostname = redis_url.hostname
  redis_port = redis_url.port or 6379

  require("./db") mysql_url, (err, conn) ->
    throw new Error("DB connection exception due to #{err}") if err?
    db = conn
    redis_client = redis.createClient(redis_port, redis_hostname)
    zk = require("./zk") zk_url, zk_path, db.models, redis_client, redis.createClient(redis_port, redis_hostname)

    next() for next in nexts  # release waiting request

exports.database = ->
  (req, res, next) ->
    if db is null
      nexts.push next
    else
      req.db = db
      next()

exports.zk = ->
  (req, res, next) ->
    req.zk = zk
    next()

exports.redis = ->
  (req, res, next) ->
    req.redis = redis_client
    next()
