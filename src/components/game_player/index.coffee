z = require 'zorium'
_ = require 'lodash'
log = require 'clay-loglevel'

Drawer = require '../drawer'
Spinner = require '../spinner'
GameShare = require '../game_share'
Game = require '../../models/game'
Modal = require '../../models/modal'
User = require '../../models/user'
UrlService = require '../../services/url'
GooglePlayAdService = require '../../services/google_play_ad'

EnvironmentService = require '../../services/environment'

styles = require './index.styl'

ENGAGED_PLAY_TIME = 60000 # 1 min
SHARE_MODAL_DISPLAY_PLAY_COUNT = 3

module.exports = class GamePlayer
  constructor: ({gameKey}) ->
    styles.use()

    o_game = z.observe Game.getByKey gameKey

    @state = z.state
      engagedPlayTimeout: null
      height: window.innerHeight + 'px'
      width: window.innerWidth + 'px'
      gameKey: gameKey
      game: o_game
      $spinner: new Spinner()
      $drawer: z.observe o_game.then (game) ->
        unless EnvironmentService.isMobile()
          return null

        new Drawer {game}

    @playCountPromise = Promise.all [
      Game.incrementPlayCount(gameKey)
      o_game
    ]
    .then ([playCount, game]) =>
      isReturningVisitor = playCount > 1
      if isReturningVisitor
        ga? 'send', 'event', 'game', 'retained_play', gameKey

      shouldShowModal = playCount is SHARE_MODAL_DISPLAY_PLAY_COUNT
      if shouldShowModal
        @showShareModal game
    .catch log.trace

  onBeforeUnmount: =>
    window.clearTimeout @state().engagedPlayTimeout
    window.removeEventListener 'resize', @resize
    # games can lock the orientation... we want to unlock it
    window.screen.unlockOrientation?()

  onMount: ($el) =>
    window.addEventListener 'resize', @resize
    @resize()

    @state.set
      engagedPlayTimeout:
        window.setTimeout =>
          @logEngagedPlay().catch(log.trace)
        , ENGAGED_PLAY_TIME

    User.convertExperiment('game_play').catch log.trace
    GooglePlayAdService.shouldShowAdModal().then (shouldShow) ->
      if shouldShow
        GooglePlayAdService.showAdModal()
        ga? 'send', 'event', 'google_play_ad_modal', 'show', gameKey
    .catch log.trace

    @state.game.then (game) ->
      ga? 'send', 'event', 'game', 'play', game.key

  resize: =>
    @state.set
      height: window.innerHeight + 'px'
      width: window.innerWidth + 'px'

  logEngagedPlay: =>
    User.convertExperiment('engaged_play').catch log.trace
    @state.game.then (game) ->
      ga? 'send', 'event', 'game', 'engaged_play', game.key
      User.addRecentGame(game.id)

  showShareModal: (game) =>
    @state.game.then (game) ->
      Modal.openComponent(
        component: new GameShare({game})
      )

  # if already on marketplace, keep them there with root route, otherwise
  # hard redirect to marketplace
  redirectToMarketplace: ->
    if UrlService.isRootPath()
      z.router.go '/'
    else
      window.location.href = UrlService.getMarketplaceBase()

  render: =>
    {game, width, height, $spinner, $drawer} = @state()

    if not game
      z '.z-game-player-missing',
        $spinner
        z 'button.button-ghost', {onclick: @redirectToMarketplace},
          'Return to Clay.io'
    else if game?.gameUrl
      z 'div.z-game-player',
        style:
          height: height
        z 'iframe' +
          '[webkitallowfullscreen][mozallowfullscreen][allowfullscreen]' +
          '[scrolling=no]',
              style:
                width: width
                height: height
              src: game.gameUrl
        $drawer
    else
      z '.z-game-player-missing',
        z 'div', 'Game Not Found'
        z 'button.button-ghost', {onclick: @redirectToMarketplace},
          'Return to Clay.io'
