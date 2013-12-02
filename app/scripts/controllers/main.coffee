'use strict'

# TODO: Maybe we should move the cookie functions out of this file.
setCookie = (c_name,value,exdays) ->
  exdate = new Date();
  exdate.setDate(exdate.getDate() + exdays)
  c_value = escape(value) + if exdays? then "; expires=" + exdate.toUTCString() else ""
  document.cookie = c_name + "=" + c_value
  return

getCookie = (c_name) ->
  c_value = document.cookie
  c_start = c_value.indexOf(" " + c_name + "=")
  if c_start == -1
    c_start = c_value.indexOf(c_name + "=")
  if c_start == -1
    c_value = null
  else
    c_start = c_value.indexOf("=", c_start) + 1
    c_end = c_value.indexOf(";", c_start)
    if c_end == -1
      c_end = c_value.length;
    c_value = unescape(c_value.substring(c_start,c_end));
  return c_value

gMY_TOKEN = gMY_NAME = gMY_ID = gMY_TAGS = ""

getAuthCookie = () ->
  gMY_TOKEN = getCookie("smart_token")
  gMY_NAME = getCookie("smart_name")
  gMY_ID = parseInt(getCookie("smart_id"))
  gMY_TAGS = getCookie("smart_tags")

setAuthCookie = (id, name, tags, token) ->
  setCookie("smart_token", token, 30)
  setCookie("smart_name", name, 30)
  setCookie("smart_id", id, 30)
  setCookie("smart_tags", tags, 30)

# Agular module definition begins here.
angular.module('angApp')
  .controller 'appCtrl', ($rootScope, $scope, $location) ->
    getAuthCookie()
    $rootScope.isLogin = () ->
      return !(typeof gMY_TOKEN == undefined or gMY_TOKEN == "") return true else false
    $rootScope.getUserName = () ->
      return gMY_NAME
    $rootScope.isAdmin = () ->
      return if "system:role:admin" in gMY_TAGS then true else false
    $rootScope.logout = () ->
      gMY_TOKEN = gMY_NAME = gMY_ID = gMY_TAGS = ""
      setAuthCookie("", "", [], "")
      $location.path "/login"
      return
    $rootScope.manageusers = () ->
      $location.path "/mgtusers"
      return
    $rootScope.managetags = () ->
      $location.path "/mgttags"
      return
    $rootScope.managedevices = () ->
      $location.path "/mgtdevices"
      return
    $rootScope.projectdetail = (id) ->
      $location.path "/projects/"+id
      return

  .controller 'MainCtrl', ($rootScope, $scope, $http, $location) ->
    $scope.create = () ->
      $('.create_project').slideToggle()
      return
    $scope.cancel = () ->
      $('.create_project').slideUp()
      return
    $scope.deleteproject = (id) ->
      $http.get("api/projects/"+id+"/remove?access_token=" + gMY_TOKEN).success (data) ->
        return
      return
    $scope.createproject = () ->
      data =
        name:$scope.newproject
        creator_id: gMY_ID
      $http.post("api/projects?access_token=" + gMY_TOKEN, data).success (data) ->
        $rootScope.projects.push {"name": data.name, "id": data.id, "creator_id": data.creator_id}
        $('.create_project').slideUp()
        return
      return
    $http.get("api/account?access_token=" + gMY_TOKEN).success (data) ->
      gMY_ID = data.id
      gMY_TAGS = data.tags
      gMY_NAME = data.email or data.name
      setCookie(gMY_ID, gMY_NAME, gMY_TAGS, gMY_TOKEN)
      return
    $http.get("api/projects?access_token=" + gMY_TOKEN).success (data) ->
      $rootScope.projects = data
      return
    return

  .controller 'ProjectCtrl', ($rootScope, $routeParams, $scope, $http, $cookies, $location) ->
    $scope.getProductInfo = (job) ->
      return "- / -" if not job.device_filter.product?
      brand = if job.device_filter.product.manufacturer? then job.device_filter.product.manufacturer else "-"
      product = if job.device_filter.product.model? then job.device_filter.product.model else "-"
      brand + " / " + product
    $scope.addtask1 = (job) ->
      id = $scope.pid
      $location.path "/projects/"+id+"/addtask1"
    $scope.addtask2 = (job) ->
      id = $scope.pid
      $location.path "/projects/"+id+"/addtask2"
    $scope.addtask3 = (job) ->
      id = $scope.pid
      $location.path "/projects/"+id+"/addtask3"
    $scope.getWorkstation = (job) ->
      return "-" if not job.device_filter.mac?
      job.device_filter.mac
    $scope.getSerial = (job) ->
      return "-" if not job.device_filter.serial?
      job.device_filter.serial
    $scope.create = () ->
      $('.add_user').slideToggle()
      return
    $scope.cancel = () ->
      $('.add_user').slideUp()
      return
    $scope.deleteuser = (mail) ->
      id = $scope.pid
      data =
        email : mail
      $http.post("api/projects/"+id+"/remove_user?access_token=" + gMY_TOKEN, data).success (data) ->
        $scope.group_users.pop mail
        return
      return      
    $scope.adduser = () ->
      id = $scope.pid
      data =
        email : $scope.user_mail
      $http.post("api/projects/"+id+"/add_user?access_token=" + gMY_TOKEN, data).success (data) ->
        $scope.group_users.push email : $scope.user_mail
        return
      return
    id = $scope.pid = $routeParams.id or ""
    $http.get("api/tasks?project="+id+"&access_token=" + gMY_TOKEN).success (data) ->
      $scope.dataset = data
      return
    $http.get("api/projects/"+id+"?access_token=" + gMY_TOKEN).success (data) ->
      $scope.group_users = data.users
      return
    $http.get("api/users?access_token=" + gMY_TOKEN).success (data) ->
      $scope.xusers = data
      return    
    return

  .controller 'LoginCtrl', ($rootScope, $scope, $http, $cookies, $location) ->
    $scope.loginForm = {}
    $scope.showMessage = false
    $scope.promptMessage = ""

    $scope.login = () ->
      return if not $scope.loginForm.email? or not $scope.loginForm.password?
      # Get token indeed
      data = 
        email: $scope.loginForm.email
        password: $scope.loginForm.password
      $http.post("api/auth/get_access_token", data)
        .success (data) ->
          gMY_TOKEN = data.access_token
          gMY_NAME = $scope.loginForm.email
          setAuthCookie(gMY_ID, gMY_NAME, gMY_TAGS, gMY_TOKEN)
          $scope.showMessage = true
          $scope.promptMessage = "Done: " + data.access_token
          $location.path "/"
        .error (data, status, headers, config) ->
          # TODO: prompt
          return
        return
    $scope.register = () ->
      $http.post("api/users", $scope.loginForm)
        .success (data) ->
          data = 
            email: data.email
            password: $scope.loginForm.password
          $http.post("api/auth/get_access_token", data)
            .success (data) ->
              # b054 - 9dd8a600-4d15-11e3-bfb6-cfebdcc7445f
              console.log "Token: " + data.access_token
              gMY_TOKEN = data.access_token
              gMY_ID = data.id
              gMY_NAME = $scope.loginForm.email
              setAuthCookie(gMY_ID, gMY_NAME, gMY_TOKEN)
              #$cookie.smart_token = data.access_token
              $scope.showMessage = true
              $scope.promptMessage = "Done: " + data.access_token
            .error (data, status, headers, config) ->
              # TODO: prompt
              return
            return
        .error (data, status, headers, config) ->
          # TODO: prompt error
          $scope.error = data.error
          $scope.promptMessage = "Failed: " + data.error
          $scope.showMessage = true
      return
    $scope.showLogin = () ->
      return typeof gMY_TOKEN == undefined or gMY_TOKEN == ""
    return

  .controller 'TagMgtCtrl', ($rootScope, $scope, $http) ->
    $http.get("api/tags?access_token=" + gMY_TOKEN).success (data) ->
      $scope.tags = data
      return
    $scope.create = () ->
      $('.create_tag').slideToggle()
      return
    $scope.createtag = () ->
      stag = $scope.taglevel + ':' + $scope.tagname
      $http.post("api/tags/"+stag+"?access_token=" + gMY_TOKEN, {}).success (data) ->
        $scope.tags.push stag
        $('.create_tag').slideUp()
        return
      return
    $scope.cancel = () ->
      $('.create_tag').slideUp()
      return
    $scope.tagsplit = (str, idx) ->
      str.split(':')[idx]
    return

  .controller 'UserMgtCtrl', ($rootScope, $scope, $http, $window) ->
    $scope.seltag = {}
    $http.get("api/users?access_token=" + gMY_TOKEN).success (data) ->
      $scope.users = data
      angular.forEach data, (o, i)->
        $scope.seltag[o.id] = ""
    $http.get("api/tags?access_token=" + gMY_TOKEN).success (data) ->
      $scope.tags = data
    $scope.create = () ->
      $('.create_user').slideToggle()
      return
    $scope.cancel = () ->
      $('.create_user').slideUp()
      return
    $scope.createuser = () ->
      vdata = 
        email: $scope.user_email
        password: $scope.user_password
      $http.post("api/users/?access_token=" + gMY_TOKEN, vdata).success (data) ->
        if data.error
          console.log data.error
        else
          $scope.users.push data
          $('.create_user').slideUp()
        return
      return
    $scope.showaddtag = (id) ->
      $('.add_tag' + id).slideToggle()
      return
    $scope.hideaddtag = (id) ->
      $('.add_tag' + id).slideUp()
      return
    $scope.add_usertag = (id, vtags) ->
      vtags.push $scope.seltag[id]
      data =
        tags: vtags
      $http.post("api/users/"+id+"?access_token=" + gMY_TOKEN, data).success (data) ->
        return
      return
    $scope.remove_usertag = (id, vtags, tag) ->
      vtags.pop $scope.tagname
      data =
        tags: vtags
      $http.post("api/users/"+id+"?access_token=" + gMY_TOKEN, data).success (data) ->
        return
      return
    return

  .controller 'WksCtrl', ($rootScope, $scope, $http) ->
    $http.get("api/workstations?access_token=" + gMY_TOKEN).success (data) ->
      $scope.zks = data
    return

  .controller 'DeviceMgtCtrl', ($rootScope, $scope, $http) ->
    $scope.my_filter = {}
    $scope.seltag = {}
    $http.get("api/devices?access_token=" + gMY_TOKEN).success (data) ->
      $scope.devices = data
      angular.forEach data, (o, i)->
        $scope.seltag[o.id] = ""
      return
    $http.get("api/tags?access_token=" + gMY_TOKEN).success (data) ->
      $scope.tags = data
    $scope.showaddtag = (id) ->
      $('.add_tag' + id).slideToggle()
      return
    $scope.hideaddtag = (id) ->
      $('.add_tag' + id).slideUp()
      return
    $scope.add_devicetag = (id) ->
      vtag = $scope.seltag[id]
      $http.post("api/devices/"+id+"/tag/"+vtag+"?access_token=" + gMY_TOKEN, {}).success (data) ->
        return
      return
    $scope.remove_devicetag = (id, vtag) ->
      $http.post("api/devices/"+id+"/untag/"+vtag+"?access_token=" + gMY_TOKEN, {}).success (data) ->
        return
      return
    $scope.getWkName = (device) ->
      return if device.workstation.name? then device.workstation.name else device.workstation.mac
    return

  .controller 'DevicesCtrl', ($rootScope, $scope, $http) ->
    $scope.my_filter = {creator_id:gMY_ID}
    $http.get("api/devices?access_token=" + gMY_TOKEN).success (data) ->
      $scope.devices = data
      return
    $scope.getWkName = (device) ->
      return if device.workstation.name? then device.workstation.name else device.workstation.mac
    return

  .controller 'TasksCtrl', ($rootScope, $scope, $http) ->
    $scope.taskFilter = {creator_id:gMY_ID} # default value for "my tasks";
    $scope.myId = gMY_ID
    $http.get("api/tasks?access_token=" + gMY_TOKEN).success (data) ->
      $scope.dataset = data
    #$scope.isMyTask = (expected, task) ->
    #  return $scope.myId == task.creator.id
    $scope.getProductInfo = (job) ->
      return "- / -" if not job.device_filter.product?
      brand = if job.device_filter.product.manufacturer? then job.device_filter.product.manufacturer else "-"
      product = if job.device_filter.product.model? then job.device_filter.product.model else "-"
      brand + " / " + product
    $scope.getWorkstation = (job) ->
      return "-" if not job.device_filter.mac?
      job.device_filter.mac
    $scope.getSerial = (job) ->
      return "-" if not job.device_filter.serial?
      job.device_filter.serial
    return

  .controller 'JobsCtrl', ($rootScope, $scope, $http) ->
    $http.get("api/jobs?access_token=" + gMY_TOKEN).success (data) ->
      #$scope.jobs = data
      # for debug only.
      $scope.jobs = [
        {
        id: 12
        task: "MTBF"
        start_time: 1364969756
        group: "Apple"
        tester: "b123"
        status: "running"
        }
        {
        id: 16
        task: "App_Test"
        start_time: 1364967756
        group: "Banana"
        tester: "b321"
        status: "failed"
        }
      ]
    return

  .controller 'AddTaskCtrl3', ($rootScope, $scope, $routeParams, $http, $location) ->
    # Some initialization.
    $scope.newTaskForm = {}
    $scope.newTaskForm.jobs = []
    #createJob()
    # Data used to show as HTML select options. Contents of [manufacturers] and [products] may change each time user makes a new selection.
    $scope.platforms = []
    # Available options
    $scope.displayedOptions = 
      platforms: []
      manufacturers: []
      models: []
      devices: []
    # Selected options
    $scope.selectedOptions = 
      platforms: []
      manufacturers: []
      models: {}
      devices: []
    # Filter var
    $scope.device_filter = 
      anyDevice: true

    # Retrieve the available devices first.
    $scope.devices = []
    $scope.manufacturers = $scope.models = []
    $scope.id = $routeParams.id or ""
    initDeviceOptions = () ->
      #$scope.platforms = groupPlatform()
      #$scope.deviceOptions.manufacturers = groupProductProperties("manufacturer")
      #$scope.deviceOptions.models = groupProductProperties("model")
      $scope.displayedOptions = ['android', 'tizen'] # fake data

    $http.get("api/devices?access_token=" + gMY_TOKEN).success (data) ->
      $scope.devices = data
      device._index = i for device, i in $scope.devices
      initDeviceOptions()

    $scope.selectPlatform = ($event) ->
      el = $event.target
      index = $scope.selectedOptions.platforms.indexOf(el.value)
      if el.checked is true
        $scope.selectedOptions.platforms.push(el.value) if index is -1
      else
        $scope.selectedOptions.platforms.splice(index, 1) if index >= 0
      # Update the optional manufacturer list.

      return

    $scope.selectManufacturer = ($event) ->
      el = $event.target
      index = $scope.selectedOptions.manufacturers.indexOf(el.value)
      if el.checked is true
        $scope.selectedOptions.manufacturers.push(el.value) if index is -1
      else
        $scope.selectedOptions.manufacturers.splice(index, 1) if index >= 0
      return

    $scope.manufacturerFilter = (device) ->
      #return if $scope.selectedOptions.platforms.indexOf(device.platform) isnt -1 then true else false
      if $scope.selectedOptions.platforms.indexOf(device.platform) is -1
        return false
      # Avoid duplicated options.
      if $scope.displayedOptions.manufacturers.indexOf(device.product.manufacturer) isnt -1
        return false
      $scope.displayedOptions.manufacturers.push(device.product.manufacturer)
      return true

    $scope.manufacturerGroup = () ->
      $scope.displayedOptions.manufacturers = []
      return $scope.devices

    $scope.selectModel = ($event, _deviceIndex) ->
      el = $event.target
      #index = $scope.selectedOptions.models.indexOf(el.value)
      if el.checked is true
        #$scope.selectedOptions.models.push({el.value: _deviceIndex}) if index is -1
        $scope.selectedOptions.models[el.value] = _deviceIndex
      else
        #$scope.selectedOptions.models.splice(index, 1) if index >= 0
        delete $scope.selectedOptions.models[el.value]
      return

    $scope.modelFilter = (device) ->
      #if $scope.selectedOptions.platforms.indexOf(device.platform) is -1
      #  return false
      if $scope.selectedOptions.manufacturers.indexOf(device.product.manufacturer) is -1
        return false
      # Avoid duplicated options.
      if $scope.displayedOptions.models.indexOf(device.product.model) isnt -1
        return false
      $scope.displayedOptions.models.push(device.product.model)
      return true

    $scope.modelGroup = () ->
      $scope.displayedOptions.models = []
      return $scope.devices

    $scope.selectDevice = ($event, _deviceIndex) ->
      el = $event.target
      if el.value is "anyDevice"
        return $scope.device_filter.anyDevice # For test only
      index = $scope.selectedOptions.devices.indexOf(_deviceIndex)
      if el.checked is true
        # Seems no duplicated options for now.
        $scope.selectedOptions.devices.push(_deviceIndex) if index is -1
      else
        $scope.selectedOptions.devices.splice(index, 1) if index >= 0
      return

    $scope.deviceFilter = (device) ->
      #if $scope.selectedOptions.platforms.indexOf(device.platform) is -1
      #  return false
      #if $scope.selectedOptions.manufacturers.indexOf(device.product.manufacturer) is -1
      #  return false
      if not $scope.selectedOptions.models[device.product.model]?
        return false
      # Avoid duplicated options. - ( But seems no duplicated devices for now.)
      return true

    $scope.deviceGroup = () ->
      $scope.displayedOptions.devices = []
      return $scope.devices

    $scope.objectLength = (obj) ->
      count = 0
      for oo of obj
        count++
      return count

    $scope.submitTask = () ->
      # Two cases depending on device_filter.anyDevice:
      #   1) true: generate jobs based on models;
      #   2) false: generate jobs based on devices.
      $scope.newTaskForm.jobs = []
      if $scope.device_filter.anyDevice is true
        iii = 0
        for m, index of $scope.selectedOptions.models
          device = $scope.devices[index]
          job = {
            #no: i
            r_type: $scope.newTaskForm.r_type
            device_filter:
              platform: device.platform
              product:
                manufacturer: device.product.manufacturer
                model: m
          }
          job.no = iii++
          $scope.newTaskForm.jobs.push(job)
      else
        # job by device
        for index, i in $scope.selectedOptions.devices
          device = $scope.devices[index]
          tokens = device.id.split("-")
          job = 
            #no: i
            r_type: $scope.newTaskForm.r_type
            device_filter:
              platform: device.platform
              mac: tokens[0]
              serial: tokens[1]
          job.no = i
          $scope.newTaskForm.jobs.push(job)

      $http.post("api/tasks?project="+$scope.id+"&access_token=" + gMY_TOKEN, $scope.newTaskForm).success (data) ->
        $location.path "/projects/"+$scope.id
        return
      return
    return


  .controller 'AddTaskCtrl2', ($rootScope, $scope, $routeParams, $http, $location) ->
    resort = () ->
      job.no = i for job, i in $scope.newTaskForm.jobs
      return
    createJob = () ->
      job = {}
      job.no = $scope.newTaskForm.jobs.length
      job.repo_url = $scope.newTaskForm.repo_url
      job.device_filter = {platform: "", manufacturer: "", model: ""}
      # Register some watchers on device selection.
      job.deviceOptions = 
        manufacturers: []
        models: []
        devices: []
      $scope.$watch('job.device_filter.platform', () ->
        if not job.device_filter.platform?
          return
          # Reset job.deviceOptions.manufacturers
        job.deviceOptions.manufacturer = []
        for d in $scope.devices
          # Filtered by platform.
          if d.platform isnt job.device_filter.platform
            continue
          if job.deviceOptions.manufacturer.indexOf(d.product.manufacturer) is -1
            job.deviceOptions.manufacturer.push(d.product.manufacturer)
      )
      $scope.$watch(job.device_filter.manufacturer, () ->
        if not job.device_filter.manufacturer?
          return
        job.deviceOptions.models = []
        for d in $scope.devices
          # Filtered by platform and manufacturer
          if d.platform isnt job.device_filter.platform
            continue
          if d.product.manufacturer isnt job.device_filter.manufacturer
            continue
          if job.deviceOptions.models.indexOf(d.product.model) is -1
            job.deviceOptions.models.push(d.product.model)
      )
      # Add the job to job list.
      $scope.newTaskForm.jobs.push(job)
      job
    removeJob = (index) ->
      return if index >= $scope.newTaskForm.jobs.length
      $scope.newTaskForm.jobs.splice(index, 1)
      resort()
      return
    # TODO: Use underscore.js
    groupPlatform = () ->
      result = []
      return result if $scope.devices.length is 0
      for d in $scope.devices
        if not d.platform?
          continue
        if result.indexOf(d.platform) is -1
          result.push(d.platform)
      result
    # TODO: Use underscore.js
    groupProductProperties = (key) ->
      result = []
      return result if $scope.devices.length is 0
      for d in $scope.devices
        #if d.product.hasOwnProperty(key) and d.product.
        if not d.product[key]?
          continue
        if result.indexOf(d.product[key]) == -1
          result.push(d.product[key])
      return result
    initDeviceOptions = () ->
      $scope.platforms = groupPlatform()
      #$scope.deviceOptions.manufacturers = groupProductProperties("manufacturer")
      #$scope.deviceOptions.models = groupProductProperties("model")

    # Some initialization.
    $scope.newTaskForm = {}
    $scope.newTaskForm.jobs = []
    #createJob()
    # Data used to show as HTML select options. Contents of [manufacturers] and [products] may change each time user makes a new selection.
    $scope.platforms = []
    $scope.id = $routeParams.id or ""
    # Retrieve the available devices first.
    $scope.devices = []
    $scope.manufacturers = $scope.models = []
    $http.get("api/devices?access_token=" + gMY_TOKEN).success (data) ->
      $scope.devices = data
      initDeviceOptions()

    # Triggered when user clicks the button to add a job in a task.
    $scope.newJob = () ->
      createJob()

    # Triggered when user clicks the button to remove an existing job in a task.
    $scope.deleteJob = (index) ->
      removeJob(index)

    # TODO: use underscore.js + Angular filter to group it.
    $scope.updateManufactures = (job) ->
      if not job.device_filter.platform?
        job.deviceOptions.manufacturers = []
        return
        # Reset job.deviceOptions.manufacturers
      job.deviceOptions.manufacturers = []
      for d in $scope.devices
        # Filtered by platform.
        if d.platform isnt job.device_filter.platform
          continue
        if job.deviceOptions.manufacturers.indexOf(d.product.manufacturer) is -1
          job.deviceOptions.manufacturers.push(d.product.manufacturer)
      return

    # TODO: use underscore.js + Angular filter to group it.
    $scope.updateModels = (job) ->
      if not job.device_filter.manufacturer?
        job.deviceOptions.models = []
        return
        # Reset job.deviceOptions.manufacturers
      job.deviceOptions.models = []
      for d in $scope.devices
        # Filtered by platform and manufacturer
        if d.platform isnt job.device_filter.platform
          continue
        if d.product.manufacturer isnt job.device_filter.manufacturer
          continue
        if job.deviceOptions.models.indexOf(d.product.model) is -1
          job.deviceOptions.models.push(d.product.model)
      return

    # TODO: use underscore.js + Angular filter to group it.
    $scope.updateDevices = (job) ->
      if not job.device_filter.model?
        job.deviceOptions.devices = []
        return
      job.deviceOptions.devices = []
      for d in $scope.devices
        # Filtered by platform and manufacturer
        if d.platform isnt job.device_filter.platform
          continue
        if d.product.manufacturer isnt job.device_filter.manufacturer
          continue
        if d.product.model isnt job.device_filter.model
          continue
        if job.deviceOptions.devices.indexOf(d.id) is -1
          job.deviceOptions.devices.push(d.id)
      return

    $scope.submitTask = () ->
      # split the device ID into mac and SN.
      for job in $scope.newTaskForm.jobs
        if job._the_device? and job._the_device.id?
          tokens = job._the_device.id.split("-")
          if tokens.length == 2
            job.device_filter = {}
            job.device_filter.mac = tokens[0]
            job.device_filter.serial = tokens[1]
          # delete _the_device
          delete job._the_device

      $http.post("api/tasks?project="+$scope.id+"access_token=" + gMY_TOKEN, $scope.newTaskForm).success (data) ->
        $location.path "/projects/"+$scope.id
        return;
      return

    return

  .controller 'AddTaskCtrl', ($rootScope, $scope, $routeParams, $http, $location) ->
    resort = () ->
      job.no = i for job, i in $scope.newTaskForm.jobs
      return
    createJob = () ->
      job = {}
      job.no = $scope.newTaskForm.jobs.length
      job.repo_url = $scope.newTaskForm.repo_url
      $scope.newTaskForm.jobs.push(job)
      job
    removeJob = (index) ->
      return if index >= $scope.newTaskForm.jobs.length
      $scope.newTaskForm.jobs.splice(index, 1)
      resort()
      return
    # TODO: Use underscore.js
    groupProductProperties = (key) ->
      result = []
      return result if $scope.devices.length is 0
      for d in $scope.devices
        #if d.product.hasOwnProperty(key) and d.product.
        if not d.product[key]?
          continue
        if result.indexOf(d.product[key]) == -1
          result.push(d.product[key])
      return result

    # Some initialization.
    $scope.newTaskForm = {}
    $scope.newTaskForm.jobs = []
    #createJob()
    $scope.id = $routeParams.id or ""
    # Retrieve the available devices first.
    $scope.devices = []
    $scope.manufacturers = $scope.models = []
    $http.get("api/devices?access_token=" + gMY_TOKEN).success (data) ->
      $scope.devices = data
      $scope.manufacturers = groupProductProperties("manufacturer")
      $scope.models = groupProductProperties("model")

    # Triggered when user clicks the button to add a job in a task.
    $scope.newJob = () ->
      createJob()

    # Triggered when user clicks the button to remove an existing job in a task.
    $scope.deleteJob = (index) ->
      removeJob(index)

    $scope.submitTask = () ->
      # split the device ID into mac and SN.
      for job in $scope.newTaskForm.jobs
        if job._the_device? and job._the_device.id?
          tokens = job._the_device.id.split("-")
          if tokens.length == 2
            job.device_filter = {}
            job.device_filter.mac = tokens[0]
            job.device_filter.serial = tokens[1]
          # delete _the_device
          delete job._the_device

      $http.post("api/tasks?project="+$scope.id+"&access_token=" + gMY_TOKEN, $scope.newTaskForm).success (data) ->
        $location.path "/projects/"+$scope.id
        return;
      return
    return

