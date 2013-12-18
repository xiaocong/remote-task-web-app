"use strict"

path = require("path")

exports.index = (req, res) ->
  res.render "index.html"

exports.views = (req, res) ->
  stripped = req.url.split('.')[0]
  requestedView = path.join './', stripped
  res.render requestedView, (err, html) ->
    if err then res.render('404') else res.send(html)
