"use strict"

exports = module.exports =
  mysql_url: process.env.MYSQL_URL or "mysql://test:12345@localhost/remote_task"
  redis_url: process.env.REDIS_URL or "redis://localhost:6379/0"
  zk_url: process.env.ZK_URL or "localhost:2181"
  zk_path: process.env.ZK_PATH or "/remote/alive/workstation"
