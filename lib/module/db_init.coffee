"use strict"

bcrypt = require 'bcrypt'
_ = require "underscore"

exports = module.exports = (db) ->
  db.models.tag.create [{tag: "system:role:admin"}, {tag: "system:role:user"}, {tag: "system:role:guest"}, {tag: "system:job:acceptable"}], (err, tags) ->
  db.models.user.create {email: "admin@localhost", password: bcrypt.hashSync("admin", bcrypt.genSaltSync(10)), name: "Administrator"}, (err, admin) ->
