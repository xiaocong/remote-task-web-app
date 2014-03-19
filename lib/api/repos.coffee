"use strict"

GitHubApi = require('github')
yaml = require('js-yaml')

module.exports = exports = Repos = 
  list: (req, res) ->
    if req.query.private in ['true', '1', 'True']
      Repos.private_repos(req, res)
    else
      Repos.public_repos(req, res)

  public_repos: (req, res) ->
    req.redis.hgetall 'opentest:task:repositories', (err, obj) ->
      return res.json(500, error: "#{err}") if err
      repos = for key, value of obj
        JSON.parse value
      res.json repos

  private_repos: (req, res) ->
    if req.user?.provider is 'github'
      github = new GitHubApi
        version: '3.0.0'
        protocol: 'https'
      github.authenticate {type: 'oauth', token: req.user.provider_token.accessToken}
      github.repos.getAll {page: Number(req.query.page) or 1, per_page: Number(req.query.per_page) or 100}, (err, result) ->
        if err
          res.json 500, error: err
        else
          res.json result
    else
      res.send 400, 'It requires valid github user.'

  readme: (req, res) ->
    github = new GitHubApi
      version: '3.0.0'
      protocol: 'https'
    if req.user?.provider is 'github'
      github.authenticate {type: 'oauth', token: req.user.provider_token.accessToken}
    github.repos.getReadme {user: req.params.user, repo: req.params.repo}, (err, result) ->
      if err?
        res.json 500, error: err
      else
        content = new Buffer(result.content, result.encoding).toString()
        res.send content

  env: (req, res) ->
    github = new GitHubApi
      version: '3.0.0'
      protocol: 'https'
    if req.user?.provider is 'github'
      github.authenticate {type: 'oauth', token: req.user.provider_token.accessToken}
    github.repos.getContent {user: req.params.user, repo: req.params.repo, path: '.init.yml'}, (err, result) ->
      if err?
        res.json 500, error: err
      else
        try
          content = new Buffer(result.content, result.encoding).toString()
          doc = yaml.safeLoad(content)
          env = doc.env or {}
          for name, value of env
            if value instanceof Array
              env[name] =
                options: value
                fix: false
                exclusive: false
            else
              env[name] =
                options: if value.options instanceof Array then value.options else []
                fix: value.fix or false
                exclusive: value.exclusive or false
          res.json env
        catch e
          return res.json 500, error: e

