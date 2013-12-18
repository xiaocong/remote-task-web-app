"use strict"

orm = require 'orm'

exports = module.exports = (url, cb) ->
  db = orm.connect url
  db.on "connect", (err, db) ->
    return cb(err) if err? and cb?

    db.load "./db_schema", (err)->

    db.sync ->
      require("./db_init")(db)
      cb(null, db) if cb?
