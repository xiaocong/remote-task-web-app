_ = require("underscore")

module.exports =
  get: (req, res) ->
    req.db.models.device_tag.find (err, tags) ->
      result = {}
      result[name] = _.map(objs, (tag)->tag.value) for name, objs of _.groupBy(tags, (tag) -> tag.name)
      if req.params.tag_name?
        res.json(result[req.params.tag_name] or [])
      else
        res.json result

  add: (req, res) ->
    req.db.models.device_tag.create [{name: req.params.tag_name, value: req.params.tag_value}], (err, tags) ->
      throw err if err?
      res.send 200
