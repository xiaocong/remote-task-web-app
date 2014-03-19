'use strict'

logger = require('./lib/logger')
dbmodule = require "./lib/module"
dbmodule.initialize ->
  logger.info 'Starting job dispatcher server...'
  require("./lib/dispatcher").schedule()
