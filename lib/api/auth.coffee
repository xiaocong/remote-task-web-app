"use strict"

uuid = require('node-uuid')
_ = require("underscore")
projects = require("./projects")
passport = require('passport')
LocalStrategy = require('passport-local').Strategy
logger = require("../logger")

auth = (req, res, next) ->
  return next() if req.user

  token_fieldname = "access_token"
  token = req.query[token_fieldname] or req.get("x-#{token_fieldname}") or req.body[token_fieldname] or req.cookies[token_fieldname]
  return res.json 401, error: "access token needed." if not token

  req.db.models.user_token.find {access_token: token}, (err, tokens) ->
    return res.json(401, error: "Invalid access token.") if err or tokens.length is 0
    req.db.models.user.get tokens[0].user_id, (err, user) ->
      req.user = user
      next(err)

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
      return next(err) if err
      if projects.length > 0
        next()
      else
        res.json 403, error: "No permission to access the task."

  auth_admin: [auth, auth_admin]

  login: (req, res, next) ->
    passport.authenticate("local", (err, user) ->
        return next(err) if err
        return res.json(401) if not user
        req.login user, (err) ->
          return next(err) if err
          info = JSON.parse(JSON.stringify user)
          delete info.password
          res.json info
    )(req, res, next)

  logout: (req, res) ->
    req.logout()
    res.send 200

  localStrategy: new LocalStrategy { # local authentication strategy
      usernameField: "email"
      passwordField: "password"
    }
    , (email, password, done) ->
      db = require("../module").db()
      db.models.user.find {email: email}, (err, users) ->
        return done(err) if err
        user = users[0]
        if user?.compare(password)
          user.getToken (err, token) ->
            if err
              token = uuid.v1()
              db.models.user_token.create {access_token: token, user_id: user.id}, (err, token) ->
                return done(err) if err
                user.access_token = token.access_token
                done null, user
            else
              user.access_token = token.access_token
              done null, user
        else
          done null, false, error: "Invalid username or password."

  serializeUser: (user, done) -> # serialize user id to session cookies
    done null, user.id

  deserializeUser: (id, done) -> # deserialize user info via session cookies
    db = require("../module").db()
    db.models.user.get id, (err, user) ->
      done err, user
