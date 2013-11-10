"use strict"

winston = require('winston')

logger = new winston.Logger
  transports: [
    new winston.transports.Console
    # new winston.transports.File filename: 'somefile.log'
  ]

exports = module.exports = logger