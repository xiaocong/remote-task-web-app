"use strict"

winston = require('winston')

if "development" is process.env.NODE_ENV
  logger = new winston.Logger
    transports: [
      new winston.transports.Console {level: "debug", colorize: true, timestamp: true}
      # new winston.transports.File filename: 'somefile.log'
    ]
else
  logger = new winston.Logger
    transports: [
      new winston.transports.Console {level: "info", colorize: true, timestamp: true}
      # new winston.transports.File filename: 'somefile.log'
    ]

exports = module.exports = logger