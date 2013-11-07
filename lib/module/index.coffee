"use strict"

orm = require "orm"
redis = require("redis")

exports.database = (db_url) ->
  db = null
  return (req, res, next) ->
    if db is null
      db = require("./db") db_url, (err, db) ->
        req.db = db
        next()
    else
      req.db = db
      next()

exports.zk = (zk_url, path) ->
  zk = null

  return (req, res, next) ->
    if zk is null
      zk = require("./zk") zk_url, path, req.db, req.redis
    req.zk = zk
    next()

exports.redis = (redis_url, options) ->
  url = require("url").parse redis_url
  hostname = url.hostname
  port = url.port or 6379
  db = Number((url.pathname or "/0")[1..])

  redis_client = null
  (req, res, next) ->
    if redis_client is null
      redis_client = redis.createClient(port, hostname, options)
      if db isnt 0
        return redis_client.select db, ->
          req.redis = redis_client
          next()
    req.redis = redis_client
    next()
