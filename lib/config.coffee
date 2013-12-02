"use strict"

exports = module.exports =
  mysql_url: process.env.MYSQL_URL or "mysql://test:12345@192.168.7.233/remote_task"
  redis_url: process.env.REDIS_URL or "redis://192.168.7.233:6379/0"
  zk_url: process.env.ZK_URL or "192.168.7.233:2181"
  zk_path: process.env.ZK_PATH or "/remote/alive/workstation"
