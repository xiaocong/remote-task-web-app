# Description:
#   Utility commands surrounding Hubot uptime.
#
# Commands:
#   hubot list devices - list all devices attached to workstations.
#   hubot list workstations - list all connected workstations.
#   hubot list jobs - list all running/new jobs.


dbmodule = require "../lib/module"

rooms = process.env.HUBUT_ANNOUNCE_ROOMS?.split(",")
until rooms
  robot.logger.error "HUBUT_ANNOUNCE_ROOMS is not set!"
  process.exit()

module.exports = (robot) ->
  announce = (msg) ->
    rooms.forEach (room) ->
      robot.messageRoom room, msg

  formatWorkstation = (ws) ->
    "#{ws.uname} - #{ws.ip} (#{ws.mac})"

  formatDevice = (dev) ->
    "#{dev.product.brand} #{dev.product.model} (#{dev.platform} #{dev.build.version.release}) - #{dev.serial}, Attached on #{formatWorkstation(dev.workstation)}"
  formatJob = (job) ->
    "#{job.id} - modified #{formatDuration(job.modified_at, new Date)}"

  formatDuration = (start, end) ->
    console.log "#{start} - #{end}"
    diff = (end - start)/1000
    days = Math.floor(diff / 3600 / 24)
    hours = Math.floor((diff / 3600) % 24)
    minutes = Math.floor((diff / 60) % 60)

    if diff < 60
      "just now"
    else
      days = if days is 0 then "" else "#{days} days "
      hours = if hours is 0 then "" else "#{hours} hours "
      minutes = if minutes is 0 then "" else "#{minutes} minutes"
      "#{[days, hours, minutes].join('')} ago"

  dbmodule.initialize ->
    require("../lib/schedule").schedule()
    data = dbmodule.data()

    robot.respond /(list|ls) (\w+)$/i, (msg) ->
      switch msg.match[2].trim()
        when "workstations", "workstation"
          wss = data.models.workstations.map (ws) ->
            "\t#{formatWorkstation(ws.toJSON())}"
          msg.send "Workstations(#{wss.length}):\n#{wss.join('\n')}"
        when "devices", "device"
          ds = data.models.devices.map (dev) ->
            "\t#{formatDevice(dev.toJSON())}"
          msg.send "Devices(#{ds.length}):\n#{ds.join('\n')}"
        when "jobs", "job"
          getJobs = (status) ->
            data.models.live_jobs.filter((job) ->job.get("status") is status).map (job) ->
              "\t#{formatJob(job.toJSON())}"
          newJobs = getJobs "new"
          runningJobs = getJobs "started"
          msg .send "Pending Jobs(#{newJobs.length}):\n#{newJobs.join('\n') or '\tNone'}\nRunning Jobs(#{runningJobs.length}):\n#{runningJobs.join('\n') or '\tNone'}"

    data.models.workstations.on "add", (ws) ->
      announce "Workstation Connected: #{formatWorkstation(ws.toJSON())}"

    data.models.workstations.on "remove", (ws) ->
      announce "Workstation Disconnected: #{formatWorkstation(ws.toJSON())}"

    data.models.devices.on "add", (dev) ->
      announce "Device Attached: #{formatDevice(dev.toJSON())}"

    data.models.devices.on "remove", (dev) ->
      announce "Device Detached: #{formatDevice(dev.toJSON())}"

    data.models.live_jobs.on "add", (job) ->
      if job.get("status") is "new"
        action = if job.get("modified_at") - job.get("created_at") < 1000 then "Created" else "Renewed"
        announce "Job #{action}: #{formatJob(job.toJSON())}"

    data.models.live_jobs.on "remove", (job) ->
      announce "Job Finished: #{formatJob(job.toJSON())}"

    data.models.live_jobs.on "change:status", (job) ->
      switch job.get("status")
        when "new"
          announce "Job Renewed: #{formatJob(job.toJSON())}"
        when "started"
          announce "Job Started: #{formatJob(job.toJSON())}"
