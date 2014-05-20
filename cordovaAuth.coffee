baioAuth = angular.module "baio-ng-cordova-auth", ["ngResource", "jmdobry.angular-cache"]

BAIO_AUTH_EVENTS =
  forbidden: 'baioAuth:FORBIDDEN',
  loginSuccess: 'baioAuth:LOGIN_SUCCESS',
  loginFailed: 'baioAuth:LOGIN_FAILED',
  logout: 'baioAuth:LOGOUT',
  redirectEnded: 'baioAuth:REDIRECT_ENDED'

baioAuth.constant('BAIO_AUTH_EVENTS', BAIO_AUTH_EVENTS)

baioAuth.factory "tokenFactory", ($angularCacheFactory) ->

  authCache = $angularCacheFactory('authCache')

  get: ->
    authCache.get "/token"

  set: (token) ->
    authCache.put "/token", token

  reset: ->
    authCache.remove "/token"


baioAuth.factory "baioAuthInterceptor", (tokenFactory, $rootScope, $q) ->

  request: (config) ->
    token = tokenFactory.get "/token"
    #console.log "interceptor", token
    if token
      config.headers.authorization = "Bearer " + token
    config


  responseError: (response) ->
    console.log "responseError", response
    if response.status == 401
      $rootScope.$broadcast BAIO_AUTH_EVENTS.forbidden, response
    $q.reject(response)

baioAuth.config ($httpProvider) ->
  $httpProvider.interceptors.push "baioAuthInterceptor"

baioAuth.config ($stateProvider) ->
  $stateProvider.state 'logon',
    url: "/logon?token",
    template: "<h1></h1>"
    controller: ($rootScope, $location, $stateParams, tokenFactory) ->
      console.log "logon"
      loginSuccess $stateParams.token, tokenFactory, $rootScope

baioAuth.run ($ionicPlatform, auth) ->
  $ionicPlatform.ready ->
    auth.load()

loginSuccess = (token, tokenFactory, $rootScope) ->
  console.log "loginSuccess", token
  tokenFactory.set token
  $rootScope.$broadcast BAIO_AUTH_EVENTS.loginSuccess

baioAuth.provider "auth", ->

  @$get = ($q, $resource, tokenFactory, $rootScope) ->

    _url = @url
    resource = $resource _url + "getProfile"

    profile: null

    load: ->
      loaded = $q.defer()
      if @profile
        loaded.resolve(@profile)
      else if tokenFactory.get()
        resource.get (res) =>
          @profile = res
          loaded.resolve(res)
        , (err) ->
          loaded.reject(err)
      else
        loaded.reject("Token not found")
      loaded.promise

    login: ->
      if window.cordova
        ref = window.open(_url, '_blank', 'location=no,toolbar=no')
        ref.addEventListener 'loadstart', (e) ->
          console.log "load start !", e
          url = e.url
          token = /\?token=(.+)$/.exec(url)
          if token
            console.log "token is #{token[1]}"
            ref.close()
            loginSuccess token[1], tokenFactory, $rootScope
      else
        window.location = _url

    logout: ->
      console.log "logout"
      @profile = null
      tokenFactory.reset()
      $rootScope.$broadcast BAIO_AUTH_EVENTS.logout

  @setUrl = (url) ->
    @url = url

  @






