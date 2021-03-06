kik = require 'kik'

class EnvironmentService
  isMobile: ->
    ///
      Mobile
    | iP(hone|od|ad)
    | Android
    | BlackBerry
    | IEMobile
    | Kindle
    | NetFront
    | Silk-Accelerated
    | (hpw|web)OS
    | Fennec
    | Minimo
    | Opera\ M(obi|ini)
    | Blazer
    | Dolfin
    | Dolphin
    | Skyfire
    | Zune
    ///.test navigator.userAgent

  isAndroid: ->
    _.contains navigator.appVersion, 'Android'

  isiOS: ->
    Boolean navigator.appVersion.match /iP(hone|od|ad)/g

  isClayApp: ->
    _.contains navigator.userAgent, 'Clay'

  isFirefoxOS: ->
    _.contains(navigator.userAgent, 'Firefox') and
    _.contains(navigator.userAgent, 'Mobile') and
    not _.contains(navigator.userAgent, 'Android') and
    not _.contains(navigator.userAgent, 'AppleWebKit')

  # Kik.enabled is not documented by Kik - could change version-by-version
  isKikEnabled: ->
    kik?.enabled

  isWebglSupported: ->
    canvas = document.createElement 'canvas'
    isWebglSupported = false

    try
      isWebglSupported = canvas.getContext('webgl')
    catch
      try
        isWebglSupported = canvas.getContext('experimental-webgl')
      catch
        isWebglSupported = null

    return isWebglSupported

module.exports = new EnvironmentService()
