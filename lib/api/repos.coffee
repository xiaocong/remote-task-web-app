"use strict"

request = require('request')
_ = require('underscore')

module.exports = exports =
  list: (req, res) ->
    url = req.query.url or require('../config').repo_url
    if m = url.match /^https:\/\/github.com\/([\w\-\.]+)\/([\w\-\.]+)/
      url = "https://raw.github.com/#{m[1]}/#{m[2]}/master/README.md"
    request url, (error, response, body) ->
      return res.json repos: [] if error or response.statusCode isnt 200
      begin = end = false
      category = []
      repos = _.map body.split(/\r\n|\r|\n/), (line) ->
        if not begin
          begin = true if line.match /^##\s+Repos/
          null
        else if end
          null
        else if line.match /^##\s+/
          end = true
          null
        else if m = line.match /^(#{3,})\s+([\w\s\.]+)/
          category[(m[1].length-3)...] = m[2]
          null
        else if m = line.match /^-\s+\[([^\[\]]+)\]\(([^\(\)]+)\)/
          name: m[1], url: m[2], category: category[..]
        else
          null
      .filter (repo) ->
        repo isnt null
      res.json repos: repos
