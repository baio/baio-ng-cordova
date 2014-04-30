"use strict"

__onCordovaPushNotifications =
  onRegistered : null
  onMsg : null
  onError : null

  onNotificationGCM: (e) ->
    switch e.event
      when 'registered'
        if e.regid.length > 0
          @onRegistered e.regid, "android"
        else
          @onError message : "GSM registration failed", data : e
      when 'message'
        @onMsg message : e.message, cnt : e.msgcnt
      when 'error'
        @onError message : "An unknown GCM error", data : e
      else
        @onError message : "An unknown GCM event has occurred", data : e

  onNotificationAPN: (event) ->
    console.log "onNotificationAPN", event
    if event.alert
      console.log "event.alert", event.alert
      #navigator.notification.alert(event.alert)
      @onMsg message : event.message
    if event.sound
      snd = new Media(event.sound)
      snd.play()
    if event.badge
      badgeSuccessHandler = ->
        console.log "badgeSuccessHandler"
      badgeErrorHandler = ->
        console.log "badgeErrorHandler"
      window.plugins.pushNotification.setApplicationIconBadgeNumber badgeSuccessHandler, badgeErrorHandler, event.badge

app.factory "cordovaPushNotifications",  ->

  onRegistered = null
  onMsg = null
  onError = null

  successToken = (token) ->
    console.log "APN  success handler", token
    __onCordovaPushNotifications.onRegistered token, "ios"

  successHandler = ->
    console.log "GSM  success handler"

  errorHandler = ->
    onError "GSM error handler"

  register: (appKey, onRegistered, onMsg, onError) ->
    if !window.cordova
      console.log "Cordova not found, suppose debug mode"
      onRegistered "-1"
      return
    __onCordovaPushNotifications.onRegistered = onRegistered
    __onCordovaPushNotifications.onMsg = onMsg
    __onCordovaPushNotifications.onError = onError
    pushNotification = window.plugins.pushNotification
    if ionic.Platform.isAndroid()
      #console.log "android"
      pushNotification.register successHandler, errorHandler, { "senderID": appKey.android, "ecb" : "__onCordovaPushNotifications.onNotificationGCM" }
    else if ionic.Platform.isIOS()
      #console.log "ios"
      pushNotification.register(successToken, errorHandler,
          badge: "true"
          sound: "true"
          alert: "true"
          ecb: "__onCordovaPushNotifications.onNotificationAPN")
    else
      throw "Unknown cordova platform"