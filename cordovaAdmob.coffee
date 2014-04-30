"use strict"


app.factory "cordovaAdmob",  ->

  successCallback = ->
    console.log "add mob created"
    requestAd()

  failureCallback = (err) ->
    console.log "add mob failed", err

  requestSuccessCallback = ->
    console.log "requestSuccessCallback suc"
    showAd()

  rqeuestFailureCallback = (err) ->
    console.log "rqeuestFailureCallback", err

  showSuccessCallback = ->
    console.log "showSuccessCallback"

  showFailureCallback = (err) ->
    console.log "showFailureCallback", err


  requestAd = ->
    window.plugins.AdMob.requestAd
      isTesting: true
      extras:
        color_bg: 'AAAAFF'
        color_bg_top: 'FFFFFF'
        color_border: 'FFFFFF'
        color_link: '000080'
        color_text: '808080'
        color_url: '008000'
      requestSuccessCallback
      rqeuestFailureCallback

  showAd = ->
    console.log "showAd"
    window.plugins.AdMob.showAd true ,showSuccessCallback, showFailureCallback

  startAd = (appkeys) ->
    #console.log "start adMob app"
    if window.plugins and window.plugins.AdMob
      appkey = if navigator.userAgent.indexOf('Android') >=0 then appkeys.android else appkeys.ios
      window.plugins.AdMob.createBannerView
        publisherId: appkey
        adSize: window.plugins.AdMob.AD_SIZE.BANNER
        'bannerAtTop': false
        successCallback
        failureCallback
    else
      console.log "Cordova AdMob not found, suppose debug mode"

  document.addEventListener 'onReceiveAd', -> console.log "onReceiveAd"
  document.addEventListener 'onFailedToReceiveAd', (evt, err) -> console.log "onFailedToReceiveAd", evt, err
  document.addEventListener 'onPresentAd', -> console.log "onPresentAd"
  document.addEventListener 'onDismissAd', -> console.log "onDismissAd"
  document.addEventListener 'onLeaveToAd', -> console.log "onLeaveToAd"

  start: startAd



