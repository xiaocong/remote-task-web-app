"use strict"

orm = require "orm"

exports.database = (db_url) ->
  db = null
  return (req, res, next) ->
    if db is null
      db = require("./db") db_url, (err, db) ->
        req.models = db.models
        next()
    else
      req.models = db.models
      next()

exports.zk = (zk_url, path) ->
  zk = null

  return (req, res, next) ->
    if zk is null
      zk = require("./zk") zk_url, path, req.models, req.redis
    req.zk = zk
    next()
