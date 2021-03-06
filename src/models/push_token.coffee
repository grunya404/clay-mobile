kik = require 'kik'
log = require 'clay-loglevel'

config = require '../config'
Game = require '../models/game'
request = require '../lib/request'

PATH = config.PUBLIC_CLAY_API_URL + '/pushTokens'

class PushToken
  createForMarketplace: =>
    @createByGameId(null)

  createByGameKey: (gameKey) =>
    Game.findOne(key: gameKey)
    .then (game) =>
      @createByGameId(game.id)

  createByGameId: (gameId) ->
    new Promise (resolve, reject) ->
      # TODO: (Austin) remove localStorage in favor of anonymous user sessions
      if localStorage['pushTokenStored']
        resolve()
      else if kik?.ready and kik?.push
        kik.ready ->
          kik.push.getToken (token) ->
            unless token
              return reject new Error 'No push token'
            request PATH,
              method: 'POST'
              body:
                gameId: gameId
                token: token
            .then ->
              localStorage['pushTokenStored'] = 1
              resolve()
            .catch (err) ->
              # FIXME: This should store on HTTP 400 if the token already exists
              localStorage['pushTokenStored'] = 1
              reject new Error err
      else
        reject new Error 'Kik not loaded - unable to get push token'


module.exports = new PushToken()
