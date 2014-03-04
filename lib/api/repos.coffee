"use strict"

GitHubApi = require('github')

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
        res.json result
