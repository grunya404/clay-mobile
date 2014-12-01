z = require 'zorium'
log = require 'clay-loglevel'

User = require '../../models/user'
ModalHeader = require '../modal_header'

styles = require './header_background.styl'

module.exports = class GooglePlayAdModal
  constructor: ->
    styles.use()

    @ModalHeader = new ModalHeader(
      title: 'Get the app'
      isDark: true
      backgroundImage: '//cdn.wtf/d/images/google_play/google_play_banner.png'
    )

  onMount: ->
    ga? 'send', 'event', 'google_play_ad_modal', 'open'

  openGooglePlay: ->
    User.convertExperiment('to_google_play').catch log.trace
    ga? 'send', 'event', 'to_google_play', 'convert'
    window.open 'https://play.google.com/store/apps/details?id=com.clay.clay'

  render: ->
    z 'div.z-google-play-ad-modal',
      @ModalHeader
      z 'div.content',
        z 'div.message',
          'Play your favorite games even faster. '
          'Official app now on Google Play!'
        z 'button.button-ghost.is-block.install-button',
          onclick: @openGooglePlay,
          z 'i.icon.icon-arrow-down'
          z 'span.button-text', 'Install now'
