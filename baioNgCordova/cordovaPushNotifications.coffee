"use strict"

__onCordovaPushNotifications =

  onBroadcastRegistered : null
  onBroadcastError : null
  onBroadcastMessage : null

  channelHandler: (e) ->
    @onBroadcastRegistered e.uri, "wp8"

  successHandler: (e) ->
    console.log "GSM  success handler", e

  errorHandler: (err) ->
    console.log "errorHandler", err
    @onBroadcastError err

  tokenHandler: (token) ->
    console.log "APN  token handler", token
    @onBroadcastRegistered token, "ios"

  onNotificationWP8: (e) ->
    @onBroadcastMessage e.message

  onNotificationGCM: (e) ->
    console.log "onNotificationGCM", e
    switch e.event
      when 'registered'
        if e.regid.length > 0
          @onBroadcastRegistered e.regid, "android"
        else
          @onBroadcastError "GSM registration failed"
      when 'message'
        @onBroadcastMessage e.message
      when 'error'
        @onBroadcastError "An unknown GCM error"
      else
        @onBroadcastError "An unknown GCM event has occurred"

    onNotificationAPN: (e) ->
      if e.alert
        @onBroadcastMessage e.message
      if e.sound
        snd = new Media(e.sound)
        snd.play()
      if e.badge
        badgeSuccessHandler = ->
          console.log "badgeSuccessHandler"
        badgeErrorHandler = ->
          console.log "badgeErrorHandler"
        window.plugins.pushNotification.setApplicationIconBadgeNumber badgeSuccessHandler, badgeErrorHandler, e.badge

baioNgCordova.factory "cordovaPushNotifications", ($rootScope)  ->

  register: (appKey) ->

    __onCordovaPushNotifications.onBroadcastRegistered = (token, platform) ->
      $rootScope.$broadcast "device::push::registered", token : token, platform : platform

    __onCordovaPushNotifications.onBroadcastError = (msg) ->
      console.log "broadcastError", msg
      err = if typeof msg == "string" then new Error(msg) else msg
      $rootScope.$broadcast "device::push::error", err

    __onCordovaPushNotifications.onBroadcastMessage = (msg) ->
      $rootScope.$broadcast "device::push::message", msg

    if !window.cordova
      __onCordovaPushNotifications.onBroadcastRegistered null, "browser"
    else
      pushNotification = window.plugins.pushNotification
      if ionic.Platform.isAndroid()
        pushNotification.register __onCordovaPushNotifications.successHandler, __onCordovaPushNotifications.errorHandler,
          "senderID": appKey.android
          "ecb" : "__onCordovaPushNotifications.onNotificationGCM"
      else if ionic.Platform.isIOS()
        pushNotification.register(__onCordovaPushNotifications.tokenHandler, __onCordovaPushNotifications.errorHandler,
            badge: "true"
            sound: "true"
            alert: "true"
            ecb: "__onCordovaPushNotifications.onNotificationAPN")
      else if ionic.Platform.isWindowsPhone()
        pushNotification.register(__onCordovaPushNotifications.channelHandler, __onCordovaPushNotifications.errorHandler,
          "channelName": "ride-better-channel"
          "ecb": "__onCordovaPushNotifications.onNotificationWP8"
          "uccb": "__onCordovaPushNotifications.channelHandler"
          "errcb": "__onCordovaPushNotifications.errorHandler")
      else
        throw "Unknown cordova platform"

