"use strict"

bcrypt = require 'bcrypt'

exports = module.exports =
  get: (req, res) ->
    user = JSON.parse(JSON.stringify(req.user))
    delete user.password
    res.json user

  update: (req, res) ->
    if req.param("password")?
      req.user.password = bcrypt.hashSync(req.body.password, bcrypt.genSaltSync(10))
    req.user.name = req.param("name") or req.user.name
    req.user.save (err) ->
      return next(err) if err?
      user = JSON.parse(JSON.stringify(req.user))
      delete user.password
      res.json user
