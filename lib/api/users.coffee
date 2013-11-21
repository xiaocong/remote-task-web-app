"use strict"

bcrypt = require 'bcrypt'
_ = require "underscore"

dup_user_info = (user) ->
  user = JSON.parse(JSON.stringify(user))
  delete user.password
  user

exports = module.exports =
  add: (req, res, next) ->
    username = req.body.username or req.body.email
    password = req.body.password
    name = req.body.name or ""
    req.db.models.user.create {email: username, password: bcrypt.hashSync(password, bcrypt.genSaltSync(10)), name: name}, (err, user) ->
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

  reset_password: (req, res, next) ->
    id = req.params.id
    password = req.param("password")
    req.db.models.user.get id, (err, user) ->
      return next(err) if err?
      user.passowrd = bcrypt.hashSync(password, bcrypt.genSaltSync(10))
      use.save (err) ->
        return next(err) if err?
        res.send 200
