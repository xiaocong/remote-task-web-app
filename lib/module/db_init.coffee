"use strict"

bcrypt = require 'bcrypt'
_ = require "underscore"

exports = module.exports = (db) ->
  db.models.tag.create [
    {tag: "system:role:admin"}
    {tag: "system:role:user"}
    {tag: "system:role:guest"}
    {tag: "system:role:disabled"}
    {tag: "system:job:acceptable"}
  ], (err, tags) ->

  db.models.user.count (err, count) ->
    if count is 0
      db.models.user.create {
        email: "admin@example.com"
        password: bcrypt.hashSync("admin", bcrypt.genSaltSync(10))
        name: "Administrator"
        tags: ["system:role:admin"]
      } , (err, admin) ->
