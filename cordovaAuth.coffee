baioAuth = angular.module "baio-ng-cordova-auth", ["ngResource", "angular-data.DSCacheFactory"]

BAIO_AUTH_EVENTS =
  forbidden: 'baioAuth:FORBIDDEN',
  loginSuccess: 'baioAuth:LOGIN_SUCCESS',
  loginFailed: 'baioAuth:LOGIN_FAILED',
  logout: 'baioAuth:LOGOUT',
  redirectEnded: 'baioAuth:REDIRECT_ENDED'

baioAuth.constant('BAIO_AUTH_EVENTS', BAIO_AUTH_EVENTS)

baioAuth.factory "tokenFactory", (DSCacheFactory) ->

  authCache = DSCacheFactory 'authCache',
    maxAge: 1000 * 60 * 60 * 24 * 2, #Items added to this cache expire after 2 days.
    deleteOnExpire: 'aggressive', #Items will be deleted from this cache right when they expire.
    storageMode: 'localStorage'

  get: ->
    authCache.get "/token"

  set: (token) ->
    authCache.put "/token", token

  reset: ->
    authCache.remove "/token"


baioAuth.factory "baioAuthInterceptor", (tokenFactory, $rootScope, $q) ->

  request: (config) ->
    token = tokenFactory.get "/token"
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

baioAuth.provider "auth", ->

  @$get = ($q, $resource, tokenFactory, $rootScope) ->

    _url = @url
    resource = $resource _url + "getProfile"

    profile: null

    setToken: (token) ->
      tokenFactory.set token

    login: ->
      loaded = $q.defer()
      if !_url
        #if url is not defined, not use authorization mechanic at all (suits for test purposes)
        loaded.resolve()
      else if @profile
        loaded.resolve(@profile)
      else if tokenFactory.get()
        #Try to load if there is some authnetication token
        resource.get (res) =>
          @profile = res
          loaded.resolve(res)
          $rootScope.$broadcast BAIO_AUTH_EVENTS.loginSuccess, res
        , (err) ->
          $rootScope.$broadcast BAIO_AUTH_EVENTS.loginFailed, err
          loaded.reject(err)
      else
        err = "Token not found"
        $rootScope.$broadcast BAIO_AUTH_EVENTS.loginFailed, err
        loaded.reject err
      loaded.promise

    logon: (token) ->
      @setToken token
      @login()

    logout: ->
      @profile = null
      tokenFactory.reset()
      $rootScope.$broadcast BAIO_AUTH_EVENTS.logout

    openAuthService: (lang) ->

      url = _url
      if lang
        url += "?lang=" + lang
      window.location = url

      #if login request in cordova application, open new window for authorization
      if window.cordova
        ref = window.open(_url, '_blank', 'location=no,toolbar=no')
        ref.addEventListener 'loadstart', (e) ->
          url = e.url
          token = /\?token=(.+)$/.exec(url)
          if token
            console.log "token is #{token[1]}"
            ref.close()
            loginSuccess token[1], tokenFactory, $rootScope
      else
        # if common web app, use same window
        window.location = _url

  @setUrl = (url) ->
    @url = url

  @






