'use strict'

schedule = require('node-schedule')
GitHubApi = require('github')
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
    q: 'opentest.task in:name'
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
      hash[item.id] = JSON.stringify(item) for item in repos.items when item.name.match(/^opentest.task\s*-/)
      redis.hmset 'opentest:task:repositories', hash
      if page < Math.ceil(repos.total_count/per_page)
        updateTaskRepos page + 1, per_page

# schedule it every minute
schedule.scheduleJob '* * * * *', ->
  logger.info 'Update opentest.task repos.'
  updateTaskRepos 1, 100
