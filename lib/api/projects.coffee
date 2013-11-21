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
        console.log JSON.stringify(req.project)
        if req.project?
          next()
        else
          res.json 403, error: "No permission to access the project."
    else
      next()

  add: (req, res, next) ->
    name = req.param("name")
    priority = 1
    tags = _.union(["system:role:guest", "system:job:acceptable"], req.param("tags") or [])
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
        project
      )

  get: (req, res, next) ->
    project = JSON.parse(JSON.stringify(req.project))
    delete project.creator.password
    delete user.password for user in project.users
    res.json project
