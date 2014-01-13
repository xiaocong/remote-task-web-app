"use strict"

require("http").globalAgent.maxSockets = 10000

exports = module.exports =
  mysql_url: process.env.MYSQL_URL or "mysql://test:12345@localhost/remote_task?pool=true"
  redis_url: process.env.REDIS_URL or "redis://localhost:6379/0"
  zk_url: process.env.ZK_URL or "localhost:2181"
  zk_path: process.env.ZK_PATH or "/remote/alive/workstation"
  baidu:
    clientID: process.env.BAIDU_CLIENT_ID or "TCu2xNrEdauk8xc1z71chcen"
    clientSecret: process.env.BAIDU_CLIENT_SECRET or "AcoVYA0lAGaEYfvoFjnXOFCT6f7TnKPH"
    callbackURL: process.env.BAIDU_CALLBACK_URL or "http://localhost:#{process.env.PORT or 3000}/api/auth/baidu/callback"
