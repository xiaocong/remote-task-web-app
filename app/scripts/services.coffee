# TODO: Maybe we should move the cookie functions out of this file.


# Roles of authentication service: login/logout, get basic info (a bit weird to store data in $rootScope...)
angular.module('services.authService', [])
  .factory('authService', ['$rootScope', '$location', '$http', ($rootScope, $location, $http) ->
    auth = []

    setCookie = (c_name,value,exdays) ->
      exdate = new Date();
      exdate.setDate(exdate.getDate() + exdays)
      c_value = escape(value) + if exdays? then "; expires=" + exdate.toUTCString() else ""
      document.cookie = c_name + "=" + c_value+ "; path=/"
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

    #gMY_TOKEN = ""
    gMY_NAME = ""
    gMY_ID = ""
    gMY_TAGS = ""

    getAuthCookie = () ->
      #gMY_TOKEN = getCookie("access_token")
      gMY_NAME = getCookie("smart_name")
      gMY_ID = parseInt(getCookie("smart_id"))
      gMY_TAGS = getCookie("smart_tags")

    setAuthCookie = (id, name, tags) ->
      #setCookie("access_token", "", 30)
      setCookie("smart_name", name, 30)
      setCookie("smart_id", id, 30)
      setCookie("smart_tags", tags, 30)

    resetAuthCookie = () ->
      #gMY_TOKEN = ""
      gMY_NAME = ""
      gMY_ID = ""
      gMY_TAGS = ""
      setAuthCookie("", "", "")

    getAccount = () ->
      $http.get("/api/account")
        .success (data) ->
          gMY_ID = data.id
          gMY_NAME = data.email or data.name
          gMY_TAGS = data.tags
          setAuthCookie(gMY_ID, gMY_NAME, gMY_TAGS)
          $rootScope.initbasicinfo()
          #$location.path "/"
        .error (data, status, headers, config) ->
          # Never reaches here since HTTP 401 has been captured in interceptor.
          logoutQuietly()
        return

    logoutQuietly = () ->
      resetAuthCookie()
      $location.path "/login"
      return

    auth.login = (name, pwd) ->
      return if not name? or not pwd?
      # Get token indeed
      data = 
        email: name
        password: pwd
      $http.post("/api/auth/login", data)
        .success (data) ->
          gMY_ID = data.id
          gMY_NAME = data.email or data.name
          gMY_TAGS = data.tags
          setAuthCookie(gMY_ID, gMY_NAME, gMY_TAGS)
          $rootScope.initbasicinfo()
          $location.path "/"

    auth.isLogin = () ->
      return (gMY_ID > 0) and (gMY_NAME?.length > 0)
    auth.getUserName = () ->
      return gMY_NAME
    auth.getToken = () ->
      #return gMY_TOKEN
      return ""
    auth.getUserId = () ->
      return gMY_ID
    auth.isAdmin = () ->
      return if gMY_TAGS.indexOf("system:role:admin") >=0 then true else false
    auth.logout = () ->
      resetAuthCookie()
      $http.post("/api/auth/logout").success (data) ->
        $location.path "/login"
      return
    $rootScope.$on('event:auth-loginRequired', () ->
      # Clear all cookies and reset login state.
      logoutQuietly()
    )
    # Start to authenticate here.
    getAccount()
    #getAuthCookie()
    #logoutQuietly() if not auth.isLogin()
    $rootScope.auth = auth
    return auth
  ])

# TODO: move this to a separate service file.
angular.module('services.naviService', ['services.authService'])
  .factory('naviService', ['$rootScope', '$location', '$http', 'authService', ($rootScope, $location, $http, authService) ->
    $rootScope.projects = []
    $rootScope.getProjectName = (id) ->
      result = p.name for p, i in $rootScope.projects when p.id is id
      return if result? then result else "Project"
    $rootScope.getTaskName = (id) ->
      result = $rootScope.task?.name
      return if result? then result else "Task"
    $rootScope.initbasicinfo = () ->
      if not authService.isLogin()
        return
      $http.get("api/projects").success (data) ->
        $rootScope.projects = data
        # Update navi data 
        breadcrumbsService.onDataChanged()
        return

    breadcrumbs = []
    breadcrumbsService = {}

    # keep this static map consitent with routers set in $routeProvider.
    TokenMap = 
      "": "Home"
      projects: $rootScope.getProjectName
      tasks: $rootScope.getTaskName
      jobs: ""
      members: "Members"
      users: "Users"
      devices: "Devices"
      account: "Account Info"
      addtask: "Create Task"
      mgtdevices: "Devices"
      tags: "Tags"
      mgtusers: "Users"
      workstations: "Workstations"
      login: "Login"
      addaccount: "Create User"
      admin: ""
      stream: "Streaming"
      mjobs: "Jobs"
      result: "Result"

    getTokenValue = (key, id) ->
      return "TODO" if not TokenMap[key]?
      if typeof(TokenMap[key]) is "function"
        result = TokenMap[key].call(this, id)
        return result
      else
        return TokenMap[key]

    buildNavigationItems = () ->
      tokens = $location.path().split('/')
      path = $location.path()
      result = []
      ii = 0
      while tokens[ii]?
        if isNaN(tokens[ii+1]) is false
          label = getTokenValue(tokens[ii], parseInt(tokens[ii+1]))
          path = tokens.slice(0, ++ii+1).join("/")
        else 
          label = getTokenValue(tokens[ii])
          path = tokens.slice(0, ii+1).join("/")
        ii++
        continue if label.length is 0
        item = 
          name: label
          path: path
        result.push(item)
      result[result.length - 1].last = true
      breadcrumbs = result

    # Update breadcrumbs only when a route is actually changed.
    # $location.path() will get updated imediatelly (even if route change fails)
    $rootScope.$on '$routeChangeSuccess', (event, current) ->
      buildNavigationItems()

    breadcrumbsService.onDataChanged = () ->
      buildNavigationItems()
    breadcrumbsService.getAll = () ->
      return breadcrumbs
    breadcrumbsService.getFirst = () ->
      return breadcrumbs[0] || {}

    return breadcrumbsService
  ])

# Page service: it does nothing but return a PageControl class. We use it to combine with Bootstrap Pagination.
angular.module('services.utilService', [])
  .factory('utilService', ['$rootScope', '$location', '$http', ($rootScope, $location, $http) ->
    PageControl = (pageSize, paginations, retrieveDataCb) ->
      this.pageSize = pageSize # How many items we want to show in one page. 
      this.paginations = paginations # How many paginations (or buttons) to show.
      this.retrieveDataCb = retrieveDataCb
      this.pageIndex = 0 # Which page is currently shown.
      this.pageCount = 0 # Total pages, got from server
      this.pageIndicators = [] # Map to the buttons on web page.
      for i in [0..this.paginations-1]
        this.pageIndicators[i] = 
          show: (i is 0)
          index: i
      return this
    PageControl.prototype.prev = () ->
      return if this.pageIndicators[0].index <= 0
      for i in [0..this.paginations-1]
        this.pageIndicators[i].index = this.pageIndicators[i].index - this.paginations
        this.pageIndicators[i].show = (this.pageIndicators[i].index < this.pageCount)
        this.pageIndicators[i].disable = (this.pageIndicators[i].index is this.pageIndex)
    PageControl.prototype.next = () ->
      return if this.pageIndicators[this.paginations-1].index >= this.pageCount
      for i in [0..this.paginations-1]
        this.pageIndicators[i].index += this.paginations
        this.pageIndicators[i].show = (this.pageIndicators[i].index < this.pageCount)
        this.pageIndicators[i].disable = (this.pageIndicators[i].index is this.pageIndex)
    PageControl.prototype.goto = (index) ->
      this.pageIndex = this.pageIndicators[index].index
      this.retrieveDataCb() if this.retrieveDataCb
    PageControl.prototype.update = (totalPages) ->
      this.pageCount = totalPages
      multiple = (this.pageIndex / this.paginations) | 0
      offset = this.pageIndex % this.paginations
      for i in [0..this.paginations-1]
        this.pageIndicators[i].index = multiple * this.paginations + i
        this.pageIndicators[i].show = (this.pageIndicators[i].index < this.pageCount)
        this.pageIndicators[i].disable = (this.pageIndicators[i].index is this.pageIndex)
      return

    theService = {}
    theService.PageControl = PageControl
    return theService
  ])