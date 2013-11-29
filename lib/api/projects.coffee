"use strict"

_ = require("underscore")

tag_project = (project, tags, cb=null) ->
  db = require("../module").db()
  db.models.tag.find (err, allTags) ->
    project.addTags _.filter(allTags, (t) -> t.tag in tags), (err) ->
      cb(err) if cb?

exports = module.exports =
  param: (req, res, next) ->
    project_id = req.param("project") or req.get("x-project")
    if project_id?
      req.user.getProjects (err, projects) ->
        return next(err) if err?
        req.project = _.find(projects, (proj) ->
          proj.id is Number(project_id)
        )
        if req.project?
          next()
        else
          res.json 403, error: "No permission to access the project."
    else
      next()

  add: (req, res, next) ->
    name = req.param("name") or "Project created at #{new Date}"
    priority = req.user.priority
    tags = _.union(["system:job:acceptable"], req.param("tags") or [], req.user.tags)
    req.db.models.project.create {name: name, priority: priority, creator_id: req.user.id}, (err, project) ->
      return next(err) if err?
      tag_project project, tags, (err) ->
        return next(err) if err?
        project.addUsers req.user, {owner: true}, (err) ->
          return next(err) if err?
          res.json project

  list: (req, res, next) ->
    req.user.getProjects (err, projects) ->
      return next(err) if err?
      res.json _.map(projects, (project) ->
        project = JSON.parse(JSON.stringify(project))
        delete project.creator.password
        delete user.password for user in project.users
        project.tags = _.map project.tags, (tag) -> tag.tag
        project
      )

  get: (req, res, next) ->
    project = JSON.parse(JSON.stringify(req.project))
    delete project.creator.password
    delete user.password for user in project.users
    project.tags = _.map project.tags, (tag) -> tag.tag
    res.json project

  add_user: (req, res, next) ->
    if req.user.id isnt req.project.creator_id
      return res.json 403, error: "Only creator has permission to add user."
    email = req.param("email")
    if not email
      return res.json 400, error: "no email parameter."
    req.db.models.user.find {email: email}, (err, users) ->
      return next(err) if err?
      return res.json 404, error: "Specified email doesn't exists." if users.length is 0
      req.project.addUsers users, (err) ->
        return next(err) if err?
        res.send 200

  rm_user: (req, res, next) ->
    if req.user.id isnt req.project.creator_id
      return res.json 403, error: "Only creator has permission to remove user."
    email = req.param("email")
    if not email
      return res.json 400, error: "no email parameter."
    if email is req.user.email
      return res.json 400, error: "can not remove yourself."
    req.db.models.user.find {email: email}, (err, users) ->
      return next(err) if err?
      return res.json 404, error: "Specified email doesn't exists." if users.length is 0
      req.project.removeUsers users, (err) ->
        return next(err) if err?
        res.send 200

  get_device: (req, res) ->
    if _.every(req.project.tagList(), (tag) -> tag in req.device.get("tags"))
      res.json req.device.toJSON()
    else
      res.json 403, error: "No permission to access the device."

  list_devices: (req, res) ->
    res.json req.zk.models.devices.filter((device) ->
      _.every(req.project.tagList(), (tag) -> tag in device.get("tags"))
    )
