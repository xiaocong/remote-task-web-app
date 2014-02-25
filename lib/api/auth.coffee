"use strict"

uuid = require('node-uuid')
_ = require("underscore")
passport = require('passport')
LocalStrategy = require('passport-local').Strategy
BearerStrategy = require('passport-http-bearer').Strategy
# BaiduStrategy = require('passport-baidu').Strategy
GithubStrategy = require('passport-github').Strategy
config = require("../config")
projects = require("./projects")
logger = require("../logger")

auth = (req, res, next) ->
  if req.user
    next()
  else
    passport.authenticate('bearer', session: false)(req, res, next)

authAdmin = (req, res, next) ->
  if "system:role:admin" in req.user.tags
    next()
  else
    res.json(403, error: "Admin permission needed.")

findUserByToken = (token, done) ->
  db = require("../module").db()
  db.models.user_token.find {access_token: token}, (err, tokens) ->
    return done(null, false) if err or tokens.length is 0
    db.models.user.get tokens[0].user_id, (err, user) ->
      done null, user or false

findOrCreateUser = (options, done) ->
  db = require("../module").db()
  switch options.provider
    when 'github' then email = options.profile._json.email
    else email = "#{options.id}@provider.#{options.provider}.com"
  db.models.user.find {email: email, provider: options.provider}, (err, users) ->
    return done(null, false) if err
    return done(null, users[0]) if users.length > 0
    db.models.user.create {
        email: email
        password: ""
        name: options.profile.username
        tags: ["system:role:guest"]
        provider: options.provider
        provider_profile: options.profile
        provider_token: options.token
      }, (err, user) ->
        done null, user or false

exports = module.exports =
  auth: auth

  auth_project: [projects.param, (req, res, next) ->
    if req.project
      next()
    else
      res.json(404, error: "Project not found.")
  ]

  authTask: (req, res, next) ->
    req.user.getProjects {id: req.task.project_id}, (err, projects) ->
      return next(err) if err
      if projects.length > 0
        req.project = projects[0]
        next()
      else
        res.json 403, error: "No permission to access the task."

  authAdmin: [auth, authAdmin]

  login: (req, res, next) ->
    passport.authenticate("local", (err, user) ->
        return next(err) if err
        return res.json(401, error: 'Authentication failed!') unless user
        req.login user, (err) ->
          return next(err) if err
          info = JSON.parse(JSON.stringify user)
          delete info.password
          res.json info
    )(req, res, next)

  logout: (req, res) ->
    req.logout()
    res.send 200

  serializeUser: (user, done) -> # serialize user id to session cookies
    done null, user.id

  deserializeUser: (id, done) -> # deserialize user info via session cookies
    require("../module").db().models.user.get id, (err, user) ->
      done null, user or false

  localStrategy: new LocalStrategy { # local authentication strategy
      usernameField: "email"
      passwordField: "password"
    }
    , (email, password, done) ->
      db = require("../module").db()
      db.models.user.find {email: email, provider: "local"}, (err, users) ->
        return done(null, false) if err
        user = users[0]
        if user?.compare(password)
          user.getToken (err, token) ->
            if err
              token = uuid.v1()
              db.models.user_token.create {access_token: token, user_id: user.id}, (err, token) ->
                return done(null, false) if err
                user.access_token = token.access_token
                done null, user
            else
              user.access_token = token.access_token
              done null, user
        else
          done null, false, error: "Invalid username or password."

  bearerStrategy: new BearerStrategy findUserByToken

  # baiduStrategy: new BaiduStrategy {
  #   clientID: config.baidu.clientID
  #   clientSecret: config.baidu.clientSecret
  #   callbackURL: config.baidu.callbackURL
  # }, (accessToken, refreshToken, profile, done) ->
  #   findOrCreateUser {
  #       id: profile.id
  #       provider: profile.provider
  #       token:
  #         accessToken: accessToken
  #         refreshToken: refreshToken
  #       profile: profile
  #     }, done

  githubStrategy: new GithubStrategy {
    clientID: config.github.clientID
    clientSecret: config.github.clientSecret
    callbackURL: config.github.callbackURL
  }, (accessToken, refreshToken, profile, done) ->
    findOrCreateUser {
        id: profile.id
        provider: profile.provider
        token:
          accessToken: accessToken
          refreshToken: refreshToken
        profile: profile
      }, done
