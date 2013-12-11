'use strict'

# TODO: move this to a separate service file.
angular.module('services.breadcrumbs', [])
  .factory('breadcrumbs', ['$rootScope', '$location', ($rootScope, $location) ->
    breadcrumbs = []
    breadcrumbsService = {}

    # Update breadcrumbs only when a route is actually changed.
    # $location.path() will get updated imediatelly (even if route change fails)
    $rootScope.$on '$routeChangeSuccess', (event, current) ->
      tokens = $location.path().split('/')
      path = $location.path()
      #console.log($location.path())
      result = []
      # TODO: Need to rewrite it when we have more complex URLs.
      switch tokens.length
        when 0, 1, 2
          result.push {name: "Home", path: "/"}
        when 3
          id = parseInt(tokens[2])
          result.push {name: "Home", path: "/"}
          result.push {name: $rootScope.getProjectName(id), path: path, class: "active"}
        when 4
          id = parseInt(tokens[2])
          result.push {name: "Home", path: "/"}
          result.push {name: $rootScope.getProjectName(id), path: tokens.splice(-1, 1).join("/")}
          result.push {name: "Create Task", path: path, class: "active"}
        else
          # TODO. Anything else for now?
          result.push {name: "Home", path: "/", active: true}
      breadcrumbs = result

    breadcrumbsService.getAll = () ->
      return breadcrumbs
    breadcrumbsService.getFirst = () ->
      return breadcrumbs[0] || {}

    return breadcrumbsService
  ])


angular.module('angApp', [
  'ngCookies',
  'ngResource',
  'ngSanitize', 
  'http-auth-interceptor', 'services.breadcrumbs'
])
  .config ['$routeProvider', '$locationProvider', ($routeProvider, $locationProvider) ->
    $routeProvider
      .when '/',
        templateUrl: 'views/main.html'
        controller: 'MainCtrl'
      .when '/login',
        templateUrl: 'views/login.html'
        controller: 'LoginCtrl'
      .when '/projects/:id',
        templateUrl: 'views/project.html'
        controller: 'ProjectCtrl'
      .when '/mgttags',
        templateUrl: 'views/tags.html'
        controller: 'TagMgtCtrl'
      .when '/mgtusers',
        templateUrl: 'views/users.html'
        controller: 'UserMgtCtrl'
      .when '/mgtdevices',
        templateUrl: 'views/devicemgt.html'
        controller: 'DeviceMgtCtrl'        
      .when '/workstations',
        templateUrl: 'views/workstations.html'
        controller: 'WksCtrl'
      .when '/devices',
        templateUrl: 'views/devices.html'
        controller: 'DevicesCtrl'
      .when '/tasks',
        templateUrl: 'views/tasks.html'
        controller: 'TasksCtrl'
      .when '/jobs',
        templateUrl: 'views/jobs.html'
        controller: 'JobsCtrl'
      .when '/projects/:id/addtask3',
        templateUrl: 'views/addtask3.html'
        controller: 'AddTaskCtrl3'
      .when '/projects/:id/addtask2',
        templateUrl: 'views/addtask2.html'
        controller: 'AddTaskCtrl2'
      .otherwise
        redirectTo: '/'
    $locationProvider.html5Mode true
  ]
