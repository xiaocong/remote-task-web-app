'use strict'

angular.module('angApp', [
  'ngCookies',
  'ngResource',
  'ngSanitize'
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
