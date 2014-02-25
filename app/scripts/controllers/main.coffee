'use strict'

AUTO_UPDATE = true
_UPDATE_INTERVAL = 5000
scheduleRefresh = (func, interval) ->
  setTimeout(func, if interval? then interval else _UPDATE_INTERVAL) if AUTO_UPDATE is true

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
      $location.path "/admin/users"
      return
    $rootScope.managetags = () ->
      $location.path "/admin/tags"
      return
    $rootScope.managedevices = () ->
      $location.path "/admin/devices"
      return
    $rootScope.managewks = () ->
      $location.path "/admin/workstations"
      return
    $rootScope.managejobs = () ->
      $location.path "/admin/mjobs"
      return
    $rootScope.projectdetail = ($event, id) ->
      return if $event.target.name is "operation_btn"
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
      $http.get("api/projects/#{ id }/remove").success (data) ->
        return
      return
    $scope.createproject = () ->
      data =
        name:$scope.newproject
        creator_id: authService.getUserId()
      $http.post("api/projects", data).success (data) ->
        $rootScope.projects.push data
        $('.create_project').slideUp()
        return
      return
    return

  .controller 'ProjectCtrl', ($rootScope, $routeParams, $scope, $http, $location) ->
    setTaskStatus = (task) ->
      #task._active = false
      task._actives = 0
      for j in task.jobs
        if j.status is "started" or j.status is "new"
          #task._active = true
          task._actives++
      return
    updateTask = (newTask) ->
      setTaskStatus(newTask)
      $scope.dataset.tasks[i] = newTask for t, i in $scope.dataset.tasks when t.id is newTask.id
      return
    hasActiveTask = (tasks) ->
      return false if not tasks?
      return true for t in tasks when t._actives > 0
    retrieveTasks = () ->
      return if $scope.$$destroyed is true
      $http.get("api/tasks?project=#{ $scope.pid }")
        .success (data) ->
          $scope.dataset = data
          initData($scope.dataset)
          # Don't have to update data automatically when all tasks are finished.
          return if not hasActiveTask($scope.dataset.tasks)
          scheduleRefresh(retrieveTasks)
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
    $scope.cfgusers = (job) ->
      id = $scope.pid
      $location.path "/projects/"+id+"/users"
    $scope.getWorkstation = (job) ->
      return "-" if not job.device_filter.mac?
      job.device_filter.mac
    $scope.getSerial = (job) ->
      return "-" if not job.device_filter.serial?
      job.device_filter.serial
    $scope.restart = (task) ->
      $http.post("api/tasks/#{ task.id }/restart")
        .success (data) ->
          updateTask(data)
          scheduleRefresh(retrieveTasks)
        .error (data, status, headers, config) ->
          result = data
          return
    $scope.cancel = (task) ->
      $http.post("api/tasks/#{ task.id }/cancel")
        .success (data) ->
          updateTask(data)
        .error (data, status, headers, config) ->
          result = data
          return
    $scope.statusFilter = (task) ->
      return ((task._actives > 0) == $scope.activeFilter)
    $scope.viewTask = ($event, task) ->
      target = if $event.target.tagName is "I" then $event.target.parentNode else $event.target
      return if target.name is "operation_btn"
      #return if $event.target.name is "operation_btn"
      $location.path "/projects/" + $scope.pid + "/tasks/" + task.id
    initData = (data) ->
      setTaskStatus(t) for t in data.tasks
      return
    $scope.activeFilter = true
    id = $scope.pid = $routeParams.id or ""
    retrieveTasks()
    $http.get("api/projects/#{ id }").success (data) ->
      $scope.group_users = data.users
      return
    return

  .controller 'GroupUserCtrl', ($rootScope, $scope, $routeParams, $http, $cookies, $location) ->
    $scope.showusers = () ->
      $http.get("api/projects/#{ id }").success (data) ->
        $scope.group_users = data.users
    $scope.showadd = () ->
      $('.add_user').slideToggle()
      return
    $scope.cancel = () ->
      $('.add_user').slideUp()
      return
    $scope.deleteuser = (mail) ->
      id = $scope.pid
      data =
        email : mail
      $http.post("api/projects/#{ id }/remove_user", data).success (data) ->
        $scope.group_users.pop mail
        return
      return      
    $scope.adduser = () ->
      id = $scope.pid
      data =
        email : $scope.user_email
      $http.post("api/projects/#{ id }/add_user", data).success (data) ->
        $scope.showusers()
        return
      return
    $rootScope.actionName = "Group User"
    id = $scope.pid = $routeParams.id or ""
    $scope.showusers()

  .controller 'LoginCtrl', ($rootScope, $scope, $http, $location, $window, authService) ->
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
    $scope.baiduLogin = ->
      $window.location.href = '/api/auth/baidu'
    return

  .controller 'TagMgtCtrl', ($rootScope, $scope, $http) ->
    $http.get("api/tags").success (data) ->
      $scope.tags = data
      return
    $scope.create = () ->
      $('.create_tag').slideToggle()
      return
    $scope.createtag = () ->
      stag = $scope.taglevel + ':' + $scope.tagname
      $http.post("api/tags/#{ stag }").success (data) ->
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

  .controller 'UserMgtCtrl', ($rootScope, $scope, $http, $window, $location) ->
    retrieveData = () ->
      $http.get("api/users").success (data) ->
        $scope.users = data
      $http.get("api/tags").success (data) ->
        $scope.tags = data
    retrieveData()
    $scope.create = () ->
      $location.url "admin/users/create"
      #$('.create_user').slideToggle()
      return
    $scope.getTagClass = (tag) ->
      key = tag.split(":")[0]
      switch key
        when "system" then return "badge badge-important"
        when "user" then return "badge badge-info"
    $scope.queryTags = (query) ->
      return $scope.tags
    $scope.tryUpdate = (uid, tags, callback) ->
      # TODO: Update UI based on HTTP POST result.
      return
    $scope.updateTag = (tag, isAdd, user) ->
      # TODO: invalidation
      action = if isAdd is true then "tag" else "untag"
      $http.post("api/users/#{ user.id }/#{ action }/#{ tag }")
        .success (data) ->
          return
        .error (data, status) ->
          # TODO: Don't have to refresh all users.
          retrieveData()
          return
    return

  .controller 'AddUserCtrl', ($scope, $http, $location) ->
    $scope.tags = []
    $scope.newUserForm = {}
    $http.get("api/tags")
      .success (data) ->
        $scope.tags = data
    validate = () ->
      return false if (not $scope.newUserForm.name?) or (not $scope.newUserForm.email?) or (not $scope.newUserForm.password?) or (not $scope.newUserForm.priority?)
      return false if not $scope.newUserForm.tags?.length > 0
      return true
    $scope.create = () ->
      return if not validate()
      $http.post("api/users", $scope.newUserForm)
        .success (data) ->
          $location.url "admin/users"
    $scope.cancel = () ->
      $location.url "admin/users"

  .controller 'WksMgtCtrl', ($rootScope, $scope, $http, $location) ->
    retrieveData = () ->
      $http.get("api/workstations").success (data) ->
        $scope.zks = data
        return
    retrieveData();
    return

  .controller 'DeviceMgtCtrl', ($rootScope, $scope, $http, $location) ->
    retrieveData = () ->
      $scope.my_filter = {}
      $http.get("api/devices").success (data) ->
        $scope.devices = data
        return
      $http.get("api/tags").success (data) ->
        $scope.tags = data
    retrieveData();
    $scope.getWkName = (device) ->
      return if device.workstation.name? then device.workstation.name else device.workstation.mac
    $scope.getTagClass = (tag) ->
      key = tag.split(":")[0]
      switch key
        when "system" then return "badge badge-important"
        when "user" then return "badge badge-info"
    $scope.queryTags = (query) ->
      return $scope.tags
    $scope.updateTag = (tag, isAdd, device) ->
      # TODO: invalidation
      action = if isAdd is true then "tag" else "untag"
      $http.post("api/devices/#{ device.id }/#{ action }/#{ tag }")
        .success (data) ->
          return
        .error (data, status) ->
          # TODO: Don't have to refresh all data.
          retrieveData()
          return
    return

  .controller 'JobMgtCtrl', ($rootScope, $scope, $http, $location) ->
    $scope.jobs = []
    fetchData = () ->
      $http.get("api/jobs")
        .success (data) ->
          now = new Date()
          $scope.jobs = data
          j._duration = parseInt((now - new Date(j.modified_at))/1000) for j in $scope.jobs
          return
    fetchData()
    $scope.duration = (job) ->
      dur = (new Date() - new Date(job.modified_at)) / 1000
      return parseInt(dur / 3600) + ":" + parseInt(dur % 3600 / 60) + ":" + parseInt(dur %60)
    $scope.cancel = (job) ->
      $http.post("api/jobs/#{ job.id }/cancel")
        .success (data) ->
          # TODO: remove it locally.
          for j, index in $scope.jobs
            if j.id is job.id
              $scope.jobs.splice(index, 1)
              return
          return
        .error (data) ->
          fetchData()
          return
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

  .controller 'JobsCtrl', ($rootScope, $routeParams, $scope, $http, $location, naviService) ->
    hasActiveJob = (jobs) ->
      return false if not jobs?
      return true for j in jobs when not (j.status is "finished" or j.status is "cancelled")
    updateJob = (job) ->
      $rootScope.task.jobs[job.no] = job
    retrieveJobs = () ->
      return if $scope.$$destroyed is true
      $http.get("api/tasks/#{ $routeParams.tid }")
        .success (data, status) ->
          now = new Date()
          $rootScope.task = data
          j._duration = parseInt((now - new Date(j.modified_at))/1000) for j in $scope.task.jobs
          naviService.onDataChanged()
          # Don't have to update data automatically when all jobs are finished.
          return if not hasActiveJob($rootScope.task.jobs)
          scheduleRefresh(retrieveJobs)
    $scope.getDevice = (job) ->
      return "" if not job.device_filter.product?.manufacturer?.length > 0
      return job.device_filter.product.manufacturer + " / " + job.device_filter.product.model
    $scope.getIndicator = (job) ->
      return "images/green-icon.png" if job.status is "new" or job.status is "started"
      return "images/red-icon.png" if job.schedular.available_device.total is 0
      if job.schedular.available_device.idle > 0
        return "images/green-icon.png"
      else
        return "images/yellow-icon.png"
      # TODO: when should we use gray?
      return "images/gray-icon.png"
    $scope.restart = (job) ->
      $http.post("api/tasks/#{ $rootScope.task.id }/jobs/#{ job.no }/restart")
        .success (data) ->
          updateJob(data)
          scheduleRefresh(retrieveJobs)
        .error (data, status) ->
          result = data
          return
    $scope.cancel = (job) ->
      $http.post("api/tasks/#{ $rootScope.task.id }/jobs/#{ job.no }/cancel")
        .success (data) ->
          updateJob(data)
        .error (data, status) ->
          result = data
          return
    $scope.stream = (job) ->
      $location.url "projects/#{$routeParams.id}/tasks/#{$routeParams.tid}/jobs/#{job.no}/stream"
      return
    $scope.restartAll = () ->
      $http.post("api/tasks/#{ rootScope.id }/restart")
        .success (data) ->
          $rootScope.task = data
          scheduleRefresh(retrieveJobs)
        .error (data, status) ->
          result = data
          return
    $scope.cancelAll = () ->
      $http.post("api/tasks/#{ rootScope.id }/cancel")
        .success (data) ->
          $rootScope.task = data
        .error (data, status) ->
          result = data
          return
    $scope.viewResult = ($event, job) ->
      target = if $event.target.tagName is "I" then $event.target.parentNode else $event.target
      return if target.name is "operation_btn"
      $location.path "projects/#{$routeParams.id}/tasks/#{$routeParams.tid}/jobs/#{job.no}/result"
      return
    $rootScope.task = {}
    retrieveJobs()
    return

  .controller 'StreamCtrl', ($rootScope, $routeParams, $scope, $http, $timeout) ->
    $scope.MAX_CONSOLE_LN = 300
    $scope.oldData = ""
    $scope.xhr = null
    $scope.consoleElement = $("#streaming_output")
    processStream = (data) ->
      newData = data.substr($scope.oldData.length)
      $scope.oldData = data
      #return if newData.trim().length <= 0
      $scope.consoleElement = $("#streaming_output") if not $scope.consoleElement?
      #TODO:  filter out "\0"
      newData = newData.replace(/\0/g, "")
      $scope.consoleElement.append("<li>" + newData.replace(/\n/ig, "<br>") + "</li>")
      $scope.consoleElement[0].scrollTop = $scope.consoleElement[0].scrollHeight
      lis = $scope.consoleElement.children()
      #console.log lis.length
      if lis.length > $scope.MAX_CONSOLE_LN
        $scope.consoleElement[0].removeChild(lis[0])
      return
    openStream = () ->
      $scope.xhr = new XMLHttpRequest()
      $scope.xhr.open "GET", "api/tasks/#{ $routeParams.tid }/jobs/#{ $routeParams.jid }/stream", true
      $scope.xhr.onprogress = () ->
        processStream($scope.xhr.responseText)
      $scope.xhr.send()
    # close the xhr when destroyed.
    $scope.$on "$destroy", () ->
      $scope.xhr.abort() if $scope.xhr?
      # cancel the timeout service
      $timeout.cancel(loadScreenshot);
      return
    $scope.counter = 0
    $scope.time = new Date()
    loadScreenshot = () ->
      # Avoid any job after destroyed.
      return if $scope.$$destroyed is true
      $scope.counter++
      $scope.time = new Date()
      newImage = new Image()
      newImage.src = "api/tasks/#{ $routeParams.tid }/jobs/#{ $routeParams.jid }/screenshot?height=250&dummy=#{ $scope.counter % 10 }"
      newImage.onload = () ->
        el = $("#placeholder img")
        el.first().replaceWith(newImage)
        el.first().show()
        el.last().hide()
        $timeout(loadScreenshot, 5200)
        return
      newImage.onerror = () ->
        $timeout(loadScreenshot, 5200)
      # Only load screenshot after the previous one is loaded or failed.
      #$timeout(loadScreenshot, 5200)
      return
    openStream()
    loadScreenshot()

  .controller 'ScreenshotCtrl', ($rootScope, $routeParams, $scope, $http, $timeout) ->
    $scope.counter = 0
    $scope.time = new Date()
    $scope.screenshotUrl = ""
    retrieveData = () ->
      $http.get("api/tasks/#{}/jobs/#{}/screenshot")
        .success (data) ->
          return
    loadScreenshot = () ->
      # Avoid any job after destroyed.
      return if $scope.$$destroyed is true
      $scope.counter++
      $scope.time = new Date()
      el = $("#placeholder img")
      console.log "api/tasks/#{ $routeParams.tid }/jobs/#{ $routeParams.jid }/screenshot?height=400"
      img = $("<img />").attr("src", "api/tasks/#{ $routeParams.tid }/jobs/#{ $routeParams.jid }/screenshot?height=400")
        .error () ->
          el.first().hide()
          el.last().show()
          return
        .load (event) ->
          el.first().replaceWith(img)
          el.first().show()
          el.last().hide()
          return
      $timeout(loadScreenshot, 4000)
      return

    loadScreenshot1 = () ->
      # Avoid any job after destroyed.
      return if $scope.$$destroyed is true
      $scope.counter++
      $scope.time = new Date()
      newImage = new Image()
      newImage.src = "api/tasks/#{ $routeParams.tid }/jobs/#{ $routeParams.jid }/screenshot?height=400&dummy=#{ $scope.counter % 10 }"
      newImage.onload = () ->
        a = a + 1
        el = $("#placeholder img")
        el.first().replaceWith(newImage)
        el.first().show()
        el.last().hide()
        return
      $timeout(loadScreenshot1, 4000)
      return
    loadScreenshot1()
    return

  .controller 'ResultCtrl', ($rootScope, $routeParams, $scope, $http, naviService) ->
    $scope.currentIndex = 0
    $scope.result = {}
    #TODO: Rewrite pageControl as a widget.
    $scope.pageControl = {}
    retrieveData = () ->
      #$http.get("api/tasks/#{ $routeParams.tid }/jobs/#{ $routeParams.jid }/result?r=error,fail")
      $http.get("api/tasks/#{ $routeParams.tid }/jobs/#{ $routeParams.jid }/result?r=#{ $scope.pageControl.filter }&page_count=#{$scope.pageControl.pageSize}&page=#{$scope.pageControl.pageIndex}")
        .success (data) ->
          $scope.result = data
          $scope.pageControl.pageCount = $scope.result.pages
          $scope.pageControl.pageIndex = $scope.result.page
          $scope.pageControl.update()
          # Set task info in $rootScope to ensure breadcum works fine.
          $rootScope.task = $scope.result.job.task
          naviService.onDataChanged()
          return
    init = () ->
      $scope.pageControl.MAX_PAGES = 5
      $scope.pageControl.filter = "fail"
      $scope.pageControl.pageSize = 10
      $scope.pageControl.pageIndex = 0
      $scope.pageControl.pageCount = 0 # got from server
      $scope.pageControl.pages = []
      #$scope.pageControl.hasPrev = $scope.pageControl.hasNext = false
      for i in [0..$scope.pageControl.MAX_PAGES-1]
        $scope.pageControl.pages[i] = 
          show: (i is 0)
          index: i
        #$scope.pageControl.pages[i].show = (i is 0)
        #$scope.pageControl.pages[i].index = i
      return
    $scope.pageControl.prev = () ->
      return if $scope.pageControl.pages[0].index <= 0
      for i in [0..$scope.pageControl.MAX_PAGES-1]
        $scope.pageControl.pages[i].index = $scope.pageControl.pages[i].index - $scope.pageControl.MAX_PAGES
        $scope.pageControl.pages[i].show = ($scope.pageControl.pages[i].index < $scope.pageControl.pageCount)
        $scope.pageControl.pages[i].disable = ($scope.pageControl.pages[i].index is $scope.pageControl.pageIndex)
      #$scope.pageControl.hasPrev = $scope.pageControl.pages[0].index > 0
      #$scope.pageControl.hasNext = true
    $scope.pageControl.next = () ->
      return if $scope.pageControl.pages[$scope.pageControl.MAX_PAGES-1].index >= $scope.pageControl.pageCount
      for i in [0..$scope.pageControl.MAX_PAGES-1]
        $scope.pageControl.pages[i].index += $scope.pageControl.MAX_PAGES
        $scope.pageControl.pages[i].show = ($scope.pageControl.pages[i].index < $scope.pageControl.pageCount)
        $scope.pageControl.pages[i].disable = ($scope.pageControl.pages[i].index is $scope.pageControl.pageIndex)
      #$scope.pageControl.hasPrev = true
      #$scope.pageControl.hasNext = $scope.pageControl.pages[$scope.pageControl.MAX_PAGES-1].index < $scope.pageControl.pageCount-1
    $scope.pageControl.goto = (index) ->
      $scope.pageControl.pageIndex = $scope.pageControl.pages[index].index
      retrieveData()
    $scope.pageControl.update = () ->
      multiple = ($scope.pageControl.pageIndex / $scope.pageControl.MAX_PAGES) | 0
      offset = $scope.pageControl.pageIndex % $scope.pageControl.MAX_PAGES
      for i in [0..$scope.pageControl.MAX_PAGES-1]
        $scope.pageControl.pages[i].index = multiple * $scope.pageControl.MAX_PAGES + i
        $scope.pageControl.pages[i].show = ($scope.pageControl.pages[i].index < $scope.pageControl.pageCount)
        $scope.pageControl.pages[i].disable = ($scope.pageControl.pages[i].index is $scope.pageControl.pageIndex)
      #$scope.pageControl.hasPrev = $scope.pageControl.pages[0].index > 0
      #$scope.pageControl.hasNext = $scope.pageControl.pages[$scope.pageControl.MAX_PAGES-1].index < $scope.pageControl.pageCount-1
      return
    $scope.goto = $scope.pageControl.goto
    $scope.refresh = () ->
      retrieveData()
      return
    $scope.toggleFilter = () ->
      $scope.pageControl.pageIndex = 0
      retrieveData()
      return
    $scope.viewScreenshot = ($index) ->
      $scope.currentIndex = $index
      $('#myModal').modal({'show'})
      updateButton()
      loadScreenshot()
      return
    $scope.step = (s) ->
      return if $scope.currentIndex+s < 0 or $scope.currentIndex+s >= $scope.result.results.length
      $scope.currentIndex += s
      updateButton()
      loadScreenshot()
    $scope.previous = () ->
      return if $scope.currentIndex is 0
      $scope.currentIndex--
      updateButton()
      loadScreenshot()
      return
    $scope.next = () ->
      return if $scope.currentIndex is ($scope.result.results.length - 1)
      $scope.currentIndex++
      updateButton()
      loadScreenshot()
      return
    $scope.formattedTrace = (result) ->
      #return result.trace.replace(",", ", &#13; ")
      return result.trace
    updateButton = () ->
      prevBtn = $("#prev_btn")
      nextBtn = $("#next_btn")
      if $scope.currentIndex is 0
        prevBtn.addClass("disabled")
      else
        prevBtn.removeClass("disabled")
      return
      if $scope.currentIndex is ($scope.result.results.length - 1)
        nextBtn.addClass("disabled")
      else
        nextBtn.removeClass("disabled")
      return
    loadScreenshot = () ->
      # Avoid any job after destroyed.
      return if $scope.$$destroyed is true
      #$scope.time = new Date()
      $("#myLabel").text($scope.result.results[$scope.currentIndex].name)
      newImage = new Image()
      newImage.src = $scope.result.results[$scope.currentIndex].screenshot_at_failure
      newImage.onload = () ->
        el = $("#img_holder img")
        el.replaceWith(newImage)
        return
      # TODO: Handle the failed case.
      return
    init()
    retrieveData()

  .controller 'AddTaskCtrl3', ($scope, $http, $location) ->
    # Some initialization.
    $scope.newTaskForm = {}
    $scope.newTaskForm.jobs = []
    $scope.newTaskForm.r_type = "none"
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

    $http.get("api/projects/"+prjid+"/devices").success (data) ->
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

      $http.post("api/tasks?project="+$scope.id, $scope.newTaskForm).success (data) ->
        $location.path "/projects/"+$scope.id
        return
      return
    return

  .controller 'AddTaskCtrl', ($routeParams, $scope, $http, $location) ->
    # Some initialization.
    $scope.showDevice = false
    $scope.filterCondition = {_displayModel:true}
    $scope.newTaskForm = {}
    $scope.newTaskForm.jobs = []
    $scope.newTaskForm.r_type = "none"
    $scope.id = $routeParams.id
    # Retrieve the available devices first.
    $scope.devices = []

    $http.get("api/projects/"+$scope.id+"/devices").success (data) ->
      $scope.devices = data
      displayedModels = {}
      #device._selected = false for device, i in $scope.devices
      for d in $scope.devices
        d._selected = false
        if displayedModels[d.product.model] is true
          continue
        d._displayModel = true
        displayedModels[d.product.model] = true
      return

    resetSorting = (el) ->
      el.removeClass()
      el.addClass("sorting")
      return

    # TODO: Ideally we should not manipulate DOM in controller.
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

    $scope.toggleModelDevice = () ->
      device._selected = false for device, i in $scope.devices
      $scope.showDevice = !$scope.showDevice
      $scope.filterCondition = if $scope.showDevice is true then {} else {_displayModel:true}
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
        if $scope.showDevice is false
          job.device_filter.product =
            manufacturer: d.product.manufacturer
            model: d.product.model
        else # selected by device.
          job.device_filter.product =
            manufacturer: d.product.manufacturer
            model: d.product.model
          tokens = d.id.split("-")
          job.device_filter.mac = tokens[0]
          job.device_filter.serial = tokens[1]
        job.no = iii++
        $scope.newTaskForm.jobs.push(job)
      # OK to submit it now.
      $http.post("api/tasks?project="+$scope.id, $scope.newTaskForm).success (data) ->
        $location.path "/projects/"+$scope.id
        return
      return
    return
