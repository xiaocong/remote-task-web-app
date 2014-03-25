'use strict'

schedule = require('node-schedule')
GitHubApi = require('github')
request = require("request")
yaml = require('js-yaml')
_ = require('underscore')

github = new GitHubApi
  version: '3.0.0'
  debug: if process.env.NODE_ENV is 'development' then true else false
  protocol: 'https'

config = require('./lib/config')
logger = require('./lib/logger')

redis_url = require("url").parse config.redis_url
redis_hostname = redis_url.hostname
redis_port = redis_url.port or 6379
redis = require("redis").createClient(redis_port, redis_hostname)

# update public opentest.task repos
updateTaskRepos = (page, per_page) ->
  github.search.repos
    q: 'opentest.task in:name fork:true'
    sort: 'stars'
    order: 'desc'
    per_page: per_page
    page: page
    client_id: config.github.clientID
    client_secret: config.github.clientSecret
  , (error, repos) ->
    if error
      logger.error "Error when retrieving github repositories due to #{error}"
    else
      hash = {}
      items = []
      items.push item for item in repos.items when item.name.match(/^opentest.task\s*-/)
      count = items.length
      for item in items
        do (item) ->
          getEnv item.owner.login, item.name, item.default_branch, (err, environ) ->
            item.environ = if err? then {} else environ
            count--
            if count is 0
              hash[item.id] = JSON.stringify(item) for item in items
              redis.hmset 'opentest:task:repositories', hash
      if page < Math.ceil(repos.total_count/per_page)
        updateTaskRepos page + 1, per_page

getEnv = (user, repo, branch, callback) ->
  url = "https://raw.github.com/#{user}/#{repo}/#{branch}/.init.yml"
  request.get url, (err, res, body) ->
    if err? or res.statusCode isnt 200
      callback "Error when retrieving file .init.yml"
    else
      try
        doc = yaml.safeLoad body
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
        callback null, env
      catch e
        return callback e

# schedule it every minute
schedule.scheduleJob '* * * * *', ->
  logger.info 'Update opentest.task repos.'
  updateTaskRepos 1, 100
