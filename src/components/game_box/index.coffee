z = require 'zorium'
kik = require 'kik'
log = require 'clay-loglevel'

User = require '../../models/user'
Game = require '../../models/game'
UrlService = require '../../services/url'

styles = require './index.styl'

DEFAULT_GAME_BOX_ICON_SIZE = 128
MARKETPLACE_GAME_ID = '1'

module.exports = class GameBox
  constructor: ->
    styles.use()

  loadGame: (game) ->
    ga? 'send', 'event', 'game_box', 'click', game.key
    User.convertExperiment('game_box_click').catch log.trace
    z.router.go UrlService.getGameRoute {game}
    httpSubDomainUrl = UrlService.getGameSubdomain({game, protocol: 'http'})
    kik?.picker?(httpSubDomainUrl, {}, -> null)

  render: ({game, iconSize, onclick}) =>
    iconSize ?= DEFAULT_GAME_BOX_ICON_SIZE
    gameSubdomainUrl = UrlService.getGameSubdomain {game}

    z "a.z-game-box[href=#{gameSubdomainUrl}]",
      onclick: (e) =>
        e?.preventDefault()
        onclick?()
        @loadGame game
      style:
        width: "#{iconSize}px",
      z 'img.image',
        src: Game.getIconUrl game
        width: iconSize
        height: iconSize
      z '.info',
        z 'h3', game.name
