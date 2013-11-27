"use strict"

uuid = require('node-uuid')
_ = require("underscore")
projects = require("./projects")

auth = (req, res, next) ->
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

auth_admin = (req, res, next) ->
  if "system:role:admin" in req.user.tags
    next()
  else
    res.json 403, error: "Admin permission needed." 

exports = module.exports =
  auth: auth

  auth_project: [projects.param, (req, res, next) ->
    if req.project
      next()
    else
      res.json(404, error: "Project not found.")
  ]

  auth_task: (req, res, next) ->
    req.user.getProjects {id: req.task.project_id}, (err, projects) ->
      return next(err) if err?
      if projects.length > 0
        next()
      else
        res.json 403, error: "No permission to access the task."

  auth_admin: [auth, auth_admin]

  get_access_token: (req, res, next) ->
    username = req.body.username or req.body.email
    password = req.body.password
    if username? and password?
      req.db.models.user.find {email: username}, (err, users) ->
        return next(err) if err?
        user = users[0]
        if user? and user.compare(password)
          user.getToken (err, token) ->
            if err?
              token = uuid.v1()
              req.db.models.user_token.create {access_token: token, user_id: user.id}, (err, tk) ->
                return next(err) if err?
                res.json {access_token: tk.access_token}
            else
              res.json {access_token: token.access_token}
        else
          res.json 401, error: "Invalid username or password."
    else
      res.json 400, error: "No username or password provided."
