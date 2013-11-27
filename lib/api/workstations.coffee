"use strict"

logger = require("../logger")
request = require("request")
url = require("url")

module.exports =
  get: (req, res) ->
    if req.workstation?
      res.json req.workstation.toJSON()
    else
      res.json req.zk.models.workstations.toJSON()

  api: (req, res) ->
    ws = req.workstation
    if ws?.get("api")?.status is "up"
      url_str = url.format(
        protocol: "http"
        hostname: ws.get("ip")
        port: ws.get("api").port
        pathname: "#{ws.get("api").path}/#{req.params[0]}"
        query: req.query
      )
      req.pipe(request(url_str)).pipe(res)
    else
      res.json 500, error: "The workstation is invalid or down!"
