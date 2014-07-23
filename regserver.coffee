"use strict"

express = require("express")
os = require('os')
_ = require('underscore')
zookeeper = require('node-zookeeper-client')
Backbone = require('backbone')
iostream = require('socket.io-stream')

logger = require('./lib/logger')

app = express()
server = require("http").createServer(app)
io = require('socket.io').listen(server)

app.set 'port', process.env.PORT or 3100
app.set 'endpoint', process.env.ENDPOINT or '/ws-proxy'
app.set 'zk_root', process.env.ZK_ROOT or '/remote/alive/workstation'
app.set 'zk_url', process.env.ZK_URL or "localhost:2181"
app.enable 'trust proxy'
app.use express.logger(stream: {write: (msg, encode) -> logger.info(msg)})
app.use express.methodOverride()

io.set 'logger', logger
if "development" is app.get("env")
  app.use express.errorHandler()
  io.set('log level', 3)
else
  io.set('log level', 1)
app.use app.router # api router

wss = {}
app.all "#{app.get 'endpoint'}/:mac/*", (req, res) ->
  return res.send(404) if req.params.mac not of wss
  stream = iostream.createStream()
  options = wss[req.params.mac].request
    path: "/api/#{req.params[0]}"
    method: req.method
    headers: req.headers
    query: req.query
  , stream, (stream, options) ->
    res.statusCode = options.statusCode
    res.set(options.headers)
    stream.on('error', (err) ->
      res.end()
    ).pipe res
  req.pipe stream
  res.on 'close', ->
    wss[req.params.mac].socket.emit 'close-http-response', id: options.id

ip = do ->
  ifaces = os.networkInterfaces()
  for dev, addrs of ifaces when dev isnt 'lo'
    for addr in addrs when addr.family is 'IPv4' and addr.address isnt '127.0.0.1'
      return addr.address

http = do ->
  _id = 0
  events = {}
  _.extend events, Backbone.Events
  (socket) ->
    socket.on 'disconnect', ->
      iostream(socket).removeAllListeners 'response'
    iostream(socket).on 'response', (stream, options) ->
      events.trigger "id:#{options.id}", stream, options
    (options, stream, callback) ->
      options.id = _id++
      iostream(socket).emit 'http', stream, options
      logger.debug "Sending http request, id is #{options.id}"
      events.once "id:#{options.id}", (stream, options) ->
        logger.debug "Received http response, id is #{options.id}"
        callback stream, options
      options

zk = zookeeper.createClient(app.get('zk_url'))
zk.connect()
zk.once 'connected', ->
  zk.mkdirp app.get('zk_root'), (err) ->
    return process.exit(-1) if err
    zk_point = (mac) ->
      "#{app.get('zk_root')}/#{mac}"
    io.of(app.get('endpoint')).on 'connection', (socket) ->
      logger.info "socket.io connected!"
      socket.on 'register', (msg, fn) ->
        logger.info "Receiving register message from #{msg.mac}!"
        getApi = (msg) ->
          data =
            status: msg.api?.status or 'down'
            path: "#{app.get('endpoint')}/#{msg.mac}"
            port: app.get('port')
            jobs: msg.api?.jobs ? []
            devices: {}
          data.devices.android = _.filter msg.api?.devices?.android ? [], (device) ->
            device.adb and device.product
          data
        info = new Backbone.Model
          ip: ip,
          mac: msg.mac
          uname: msg.uname
          owner: msg.owner
          api: getApi(msg)

        zk.create zk_point(msg.mac), new Buffer(JSON.stringify info.toJSON()), zookeeper.CreateMode.EPHEMERAL, (err, path) ->
          if err
            logger.info "Error during creating zk node #{msg.mac}!"
            return fn?({returncode: -1, error: err})
          logger.info "Zk node #{msg.mac} created successfully!"
          fn?(returncode: 0)

          wss[msg.mac] =
            request: http(socket)
            info: info
            socket: socket

          socket.once 'disconnect', ->  # remove zk node in case of disconnection
            logger.info "socket.io from #{msg.mac} disconnected!"
            socket.removeAllListeners()
            zk.remove path, (err) ->
            info.off()
            delete wss[msg.mac]

          info.on 'change', (event) ->
            logger.info "The status of workstation #{msg.mac} got changed!"
            zk.setData path, new Buffer(JSON.stringify info.toJSON()), (err, stat) ->
              return console.log(err) if err

          socket.on 'update', (msg, fn) ->  # update zk node
            info.set 'api', getApi(msg)
            fn(returncode: 0) if fn

server.listen app.get("port"), ->
  logger.info "Express server listening on port #{app.get('port')} in #{app.get('env')} mode."
