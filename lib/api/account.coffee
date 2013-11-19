"use strict"

bcrypt = require 'bcrypt'

exports = module.exports =
  get: (req, res) ->
    user = {}
    user[k] = v for k, v of req.user when k isnt "password"
    res.json user

  update: (req, res) ->
    if req.param("password")?
      req.user.password = bcrypt.hashSync(req.body.password, bcrypt.genSaltSync(10))
    req.user.name = req.param("name") or req.user.name
    req.user.save (err) ->
      return next(err) if err?
      user = {}
      user[k] = v for k, v of req.user when k isnt "password"
      res.json user
