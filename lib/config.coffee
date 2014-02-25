'use strict'

require('http').globalAgent.maxSockets = 10000

exports = module.exports =
  mysql_url: process.env.MYSQL_URL or 'mysql://test:12345@localhost/remote_task?pool=true'
  redis_url: process.env.REDIS_URL or 'redis://localhost:6379/0'
  zk_url: process.env.ZK_URL or 'localhost:2181'
  zk_path: process.env.ZK_PATH or '/remote/alive/workstation'
  baidu:
    clientID: process.env.BAIDU_CLIENT_ID or 'TCu2xNrEdauk8xc1z71chcen'
    clientSecret: process.env.BAIDU_CLIENT_SECRET or 'AcoVYA0lAGaEYfvoFjnXOFCT6f7TnKPH'
    callbackURL: process.env.BAIDU_CALLBACK_URL or 'http://opentest.io/api/auth/baidu/callback'
  github:
    clientID: process.env.GITHUB_CLIENT_ID or '0f9b88b9f28ffc7d8bb5'
    clientSecret: process.env.GITHUB_CLIENT_SECRET or '88a995a5abae2461fb06433f574769a92576bfa7'
    callbackURL: process.env.GITHUB_CALLBACK_URL or 'http://opentest.io/api/auth/github/callback'
  repo_url: process.env.REPO_URL or 'https://github.com/xiaocong/task-repos'
  hubot_rooms: process.env.HUBUT_ANNOUNCE_ROOMS?.split(',')
