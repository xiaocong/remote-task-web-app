"use strict"

bcrypt = require 'bcrypt'
_ = require "underscore"

dup_user_info = (user) ->
  user = JSON.parse(JSON.stringify(user))
  delete user.password
  user

exports = module.exports =
  add: (req, res, next) ->
    username = req.body.email or req.body.username
    password = req.body.password
    name = req.body.name or ""
    tags = req.body.tags or ["system:role:guest"]
    priority = Number(req.body.priority ? 1)
    req.db.models.user.create {email: username, password: bcrypt.hashSync(password, bcrypt.genSaltSync(10)), name: name, priority: priority, tags: tags}, (err, user) ->
      return next(err) if err?
      res.json dup_user_info(user)

  list: (req, res, next) ->
    req.db.models.user.find (err, users) ->
      return next(err) if err?
      res.json _.map(users, (user)-> dup_user_info(user))

  get: (req, res, next) ->
    id = req.params.id
    req.db.models.user.get id, (err, user) ->
      return next(err) if err?
      res.json dup_user_info(user)

  update: (req, res, next) ->
    id = req.params.id
    req.db.models.user.get id, (err, user) ->
      return next(err) if err?
      for prop in ["email", "priority", "name", "tags"]
        user[prop] = req.param(prop) or user[prop]
      if req.param("password")
        user.password = bcrypt.hashSync(req.param("password"), bcrypt.genSaltSync(10))
      user.save (err) ->
        return next(err) if err?
        res.json dup_user_info(user)

  reset_password: (req, res, next) ->
    id = req.params.id
    password = req.param("password")
    req.db.models.user.get id, (err, user) ->
      return next(err) if err?
      user.password = bcrypt.hashSync(password, bcrypt.genSaltSync(10))
      use.save (err) ->
        return next(err) if err?
        res.send 200
