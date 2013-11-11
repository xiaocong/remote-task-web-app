"use strict"

_ = require("underscore")

module.exports =
  get: (req, res, next) ->
    req.db.models.tag.find (err, tags) ->
      return next(err) if err?
      res.json _.map(tags, (tag) -> tag.tag)

  add: (req, res, next) ->
    req.db.models.tag.create [{tag: req.param("tag")}], (err, tags) ->
      return next(err) if err?
      res.send 200
