"use strict"

Backbone = require "backbone"
_ = require "underscore"

exports = module.exports = (models) ->
  DeviceTags = Backbone.Collection.extend(
    sync: (method, model, options) ->
      switch method
        when "read"
          models.device.find (err, devices) ->
            return options.error(err) if err

            devices_with_tag = _.filter devices, (device) ->
              device.tags.length > 0

            tags = _.map(devices_with_tag, (device) ->
              id: "#{device.workstation_mac}-#{device.serial}"
              tags: device.tagList()
            )
            options.success tags
  )

  NewJobs = Backbone.Collection.extend(
    sync: (method, model, options) ->
      switch method
        when "read"
          models.job.find {status: "new"}, (err, jobs) ->
            return options.error(err) if err
            options.success(jobs)
  )

  DeviceTags: DeviceTags, NewJobs: NewJobs
