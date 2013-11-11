"use strict"

uuid = require('node-uuid')

exports = module.exports =
  authenticate: (req, res, next) ->
    token_fieldname = "access_token"
    token = req.query[token_fieldname] or req.get("x-#{token_fieldname}") or req.body[token_fieldname]
    if token?
      req.db.models.user_token.find {access_token: token}, (err, tokens) ->
        return next(err) if err?
        if tokens.length is 0
          res.json 401, error: "Invalid access token."
        else
          req.db.models.user.get tokens[0].user_id, (err, user) ->
            return next(err) if err?
            req.user = user
            next()
    else
      res.json 401, error: "access token needed."

  admin_auth: (req, res, next) ->  # TODO
    console.log "TODO Admin auth."
    next()

  get_access_token: (req, res, next) ->
    username = req.body.username or req.body.email
    password = req.body.password
    if username? and password?
      req.db.models.user.find {email: username}, (err, users) ->
        return next(err) if err?
        user = users[0]
        console.log user, username
        if user? and user.compare(password)
          user.getToken (err, token) ->
            if err?
              token = uuid.v1()
              user.setToken access_token: token, (err, t) ->
                return next(err) if err?
                res.json {access_token: t.access_token}
            else
              res.json {access_token: token.access_token}
        else
          res.json 400, error: "Invalid username or password."
    else
      res.json 400, error: "No username or password provided."
