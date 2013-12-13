'use strict'

# Agular module definition begins here.
angular.module('angApp')
  # Inject authService & naviService at the first place to ensure all listeners work well.
  # TODO: We may need a global service to handle all gobal data and listeners.
  .controller 'AppCtrl', ($scope, $location, $route, $rootScope, authService, naviService) ->
    # Should be safe to get data here.
    $rootScope.initbasicinfo()
    return

  .controller 'SampleCtrl', ($scope, $http) ->
    $http.get('/api/awesomeThings').success (awesomeThings) ->
      $scope.awesomeThings = awesomeThings

  .controller 'NaviCtrl', ($rootScope, $scope, $location, naviService, authService) ->
    $rootScope.naviService = naviService
    $scope.auth = authService
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

  .controller 'MainCtrl', ($rootScope, $scope, $http, authService) ->
    $scope.create = () ->
      $('.create_project').slideToggle()
      return
    $scope.cancel = () ->
      $('.create_project').slideUp()
      return
    $scope.deleteproject = (id) ->
      $http.get("api/projects/"+id+"/remove?access_token=" + authService.getToken()).success (data) ->
        return
      return
    $scope.createproject = () ->
      data =
        name:$scope.newproject
        creator_id: authService.getUserId()
      $http.post("api/projects?access_token=" + authService.getToken(), data).success (data) ->
        $rootScope.projects.push {"name": data.name, "id": data.id, "creator_id": data.creator_id}
        $('.create_project').slideUp()
        return
      return
    return

  .controller 'ProjectCtrl', ($rootScope, $routeParams, $scope, $http, $location, authService) ->
    $scope.getProductInfo = (job) ->
      return "- / -" if not job.device_filter.product?
      brand = if job.device_filter.product.manufacturer? then job.device_filter.product.manufacturer else "-"
      product = if job.device_filter.product.model? then job.device_filter.product.model else "-"
      brand + " / " + product
    $scope.addtask = (job) ->
      id = $scope.pid
      $location.path "/projects/"+id+"/addtask"
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
      $http.post("api/projects/"+id+"/remove_user?access_token=" + authService.getToken(), data).success (data) ->
        $scope.group_users.pop mail
        return
      return
    $scope.adduser = () ->
      id = $scope.pid
      data =
        email : $scope.user_mail
      $http.post("api/projects/"+id+"/add_user?access_token=" + authService.getToken(), data).success (data) ->
        $scope.group_users.push email : $scope.user_mail
        return
      return
    $scope.restart = ($event, task) ->
      # TODO
      return false
    $scope.cancel = ($event, task) ->
      # TODO
      return false
    $scope.statusFilter = (task) ->
      return (task._active is $scope.activeFilter)
    $scope.viewTask = ($event, task) ->
      return if $event.target.name is "operation"
      $location.path "/projects/" + $scope.pid + "/tasks/" + task.id
    initData = (data) ->
      for t in data.tasks
        active = false
        for j in t.jobs
          if j.status is "started" or j.status is "new"
            active = true
            break
        t._active = active
      return
    $scope.activeFilter = true
    id = $scope.pid = $routeParams.id or ""
    $http.get("api/tasks?project="+id+"&access_token=" + authService.getToken()).success (data) ->
      $scope.dataset = data
      initData($scope.dataset)
      return
    $http.get("api/projects/"+id+"?access_token=" + authService.getToken()).success (data) ->
      $scope.group_users = data.users
      return
    return

  .controller 'LoginCtrl', ($rootScope, $scope, $http, $location, authService) ->
    $scope.loginForm = {}
    $scope.showMessage = false
    $scope.promptMessage = ""

    $scope.login = () ->
      return if not $scope.loginForm.email? or not $scope.loginForm.password?
      authService.login($scope.loginForm.email, $scope.loginForm.password)
    $scope.register = () ->
      ###
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
      ###
      return
    $scope.showLogin = () ->
      return not authService.isLogin()
    return

  .controller 'TagMgtCtrl', ($rootScope, $scope, $http, authService) ->
    $http.get("api/tags?access_token=" + authService.getToken()).success (data) ->
      $scope.tags = data
      return
    $scope.create = () ->
      $('.create_tag').slideToggle()
      return
    $scope.createtag = () ->
      stag = $scope.taglevel + ':' + $scope.tagname
      $http.post("api/tags/"+stag+"?access_token=" + authService.getToken(), {}).success (data) ->
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

  .controller 'UserMgtCtrl', ($rootScope, $scope, $http, $window, authService) ->
    $scope.seltag = {}
    $http.get("api/users?access_token=" + authService.getToken()).success (data) ->
      $scope.users = data
      angular.forEach data, (o, i)->
        $scope.seltag[o.id] = ""
    $http.get("api/tags?access_token=" + authService.getToken()).success (data) ->
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
      $http.post("api/users/?access_token=" + authService.getToken(), vdata).success (data) ->
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
      $http.post("api/users/"+id+"?access_token=" + authService.getToken(), data).success (data) ->
        return
      return
    $scope.remove_usertag = (id, vtags, tag) ->
      vtags.pop $scope.tagname
      data =
        tags: vtags
      $http.post("api/users/"+id+"?access_token=" + authService.getToken(), data).success (data) ->
        return
      return
    return

  .controller 'WksCtrl', ($rootScope, $scope, $http, authService) ->
    $http.get("api/workstations?access_token=" + authService.getToken()).success (data) ->
      $scope.zks = data
    return

  .controller 'DeviceMgtCtrl', ($rootScope, $scope, $http, authService) ->
    $scope.my_filter = {}
    $scope.seltag = {}
    $http.get("api/devices?access_token=" + authService.getToken()).success (data) ->
      $scope.devices = data
      angular.forEach data, (o, i)->
        $scope.seltag[o.id] = ""
      return
    $http.get("api/tags?access_token=" + authService.getToken()).success (data) ->
      $scope.tags = data
    $scope.showaddtag = (id) ->
      $('.add_tag' + id).slideToggle()
      return
    $scope.hideaddtag = (id) ->
      $('.add_tag' + id).slideUp()
      return
    $scope.add_devicetag = (id, tags) ->
      vtag = $scope.seltag[id]
      $http.post("api/devices/"+id+"/tag/"+vtag+"?access_token=" + authService.getToken(), {}).success (data) ->
        tags.push vtag
        return
      return
    $scope.remove_devicetag = (id, tags, vtag) ->
      $http.post("api/devices/"+id+"/untag/"+vtag+"?access_token=" + authService.getToken(), {}).success (data) ->
        tags.pop vtag
        return
      return
    $scope.getWkName = (device) ->
      return if device.workstation.name? then device.workstation.name else device.workstation.mac
    return

  .controller 'DevicesCtrl', ($scope, $http) ->
    $scope.my_filter = {creator_id:authService.getUserId()}
    $http.get("api/devices?access_token=" + authService.getToken()).success (data) ->
      $scope.devices = data
      return
    $scope.getWkName = (device) ->
      return if device.workstation.name? then device.workstation.name else device.workstation.mac
    return

  .controller 'TasksCtrl', ($scope, $http) ->
    $scope.taskFilter = {creator_id:authService.getUserId()} # default value for "my tasks";
    $scope.myId = authService.getUserId()
    $http.get("api/tasks?access_token=" + authService.getToken()).success (data) ->
      $scope.dataset = data
    #$scope.isMyTask = (expected, task) ->
    # return $scope.myId == task.creator.id
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

  .controller 'JobsCtrl', ($rootScope, $routeParams, $scope, $http, authService, naviService) ->
    $rootScope.task = {}
    $http.get("api/tasks/" + $routeParams.tid + "?access_token=" + authService.getToken()).success (data) ->
      $rootScope.task = data
      naviService.onDataChanged()
    return

  .controller 'AddTaskCtrl3', ($scope, $http, $location, authService) ->
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
    prjid = $scope.id = $routeParams.id or ""
    initDeviceOptions = () ->
      #$scope.platforms = groupPlatform()
      #$scope.deviceOptions.manufacturers = groupProductProperties("manufacturer")
      #$scope.deviceOptions.models = groupProductProperties("model")
      $scope.displayedOptions = ['android', 'tizen'] # fake data

    $http.get("api/projects/"+prjid+"/devices?access_token=" + authService.getToken()).success (data) ->
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
      # return false
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
      # return false
      #if $scope.selectedOptions.manufacturers.indexOf(device.product.manufacturer) is -1
      # return false
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

    $scope.cancelTask = () ->
      $location.path "/projects/"+$scope.id
      return

    $scope.submitTask = () ->
      # Two cases depending on device_filter.anyDevice:
      # 1) true: generate jobs based on models;
      # 2) false: generate jobs based on devices.
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

      $http.post("api/tasks?project="+$scope.id+"&access_token=" + authService.getToken(), $scope.newTaskForm).success (data) ->
        $location.path "/projects/"+$scope.id
        return
      return
    return

  .controller 'AddTaskCtrl2', ($routeParams, $scope, $http, $location, authService) ->
    # Some initialization.
    $scope.deviceFilter = false
    $scope.newTaskForm = {}
    $scope.newTaskForm.jobs = []
    $scope.id = $routeParams.id
    # Retrieve the available devices first.
    $scope.devices = []

    $http.get("api/projects/"+$scope.id+"/devices?access_token=" + authService.getToken()).success (data) ->
      $scope.devices = data
      device._selected = false for device, i in $scope.devices
      #device._index = i for device, i in $scope.devices

    resetSorting = (el) ->
      el.removeClass()
      el.addClass("sorting")
      return

    $scope.sortByPlatform = () ->
      resetSorting($("#sort_brand"))
      el = $("#sort_platform")
      el.removeClass()
      el.addClass(if $scope.reverse is true then "sorting_asc" else "sorting_desc")
      return

    $scope.sortByBrand = () ->
      resetSorting($("#sort_platform"))
      el = $("#sort_brand")
      el.removeClass()
      el.addClass(if $scope.reverse is true then "sorting_asc" else "sorting_desc")
      return

    $scope.cancelTask = () ->
      $location.path "/projects/"+$scope.id
      return

    $scope.setSelected = (device) ->
      device._selected = !device._selected
      return device._selected

    $scope.submitTask = () ->
      # Two cases depending on device_filter.anyDevice:
      # 1) true: generate jobs based on models;
      # 2) false: generate jobs based on devices.
      $scope.newTaskForm.jobs = []
      iii = 0
      for d in $scope.devices
        continue if d._selected is false
        # First fill in the common params.
        job = {
          r_type: $scope.newTaskForm.r_type
          device_filter:
            platform: d.platform
        }
        # selected by model.
        if $scope.deviceFilter is false
          job.device_filter.product =
            manufacturer: d.product.manufacturer
            model: d.product.model
        else # selected by device.
          tokens = d.id.split("-")
          job.device_filter.mac = tokens[0]
          job.device_filter.serial = tokens[1]
        job.no = iii++
        $scope.newTaskForm.jobs.push(job)
      # OK to submit it now.
      $http.post("api/tasks?project="+$scope.id+"&access_token=" + authService.getToken(), $scope.newTaskForm).success (data) ->
        $location.path "/projects/"+$scope.id
        return
      return
    return

  .controller 'AddTaskCtrl', ($rootScope, $scope, $routeParams, $http, $location, authService) ->
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
    $http.get("api/devices?access_token=" + authService.getToken()).success (data) ->
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

      $http.post("api/tasks?project="+$scope.id+"&access_token=" + authService.getToken(), $scope.newTaskForm).success (data) ->
        $location.path "/projects/"+$scope.id
        return;
      return
    return

