express = require 'express'
dust = require 'dustjs-linkedin'
fs = require 'fs'
_ = require 'lodash'
Promise = require 'bluebird'
useragent = require 'express-useragent'
compress = require 'compression'
log = require 'loglevel'
cookieParser = require 'cookie-parser'
request = require 'request-promise'
helmet = require 'helmet'

config = require './src/config'

API_REQUEST_TIMEOUT = 1000 # 1 second
HEALTHCHECK_TIMEOUT = 600
EIGHTEEN_WEEKS_MS = 10886400000 # 18 weeks

router = express.Router()
log.enableAll()

# Dust templates
# Don't compact whitespace, because it breaks the javascript partial
dust.optimizers.format = (ctx, node) -> node

indexTpl = dust.compile fs.readFileSync('index.dust', 'utf-8'), 'index'


distJs = if config.ENV is config.ENVS.PROD \
          then fs.readFileSync('dist/js/bundle.js', 'utf-8')
          else null

dust.loadSource indexTpl

app = express()

app.use compress()

# Security
webpackDevHost = config.WEBPACK_DEV_HOSTNAME + ':' + config.WEBPACK_DEV_PORT
scriptSrc = [
  '\'unsafe-eval\''
  '\'unsafe-inline\''
  'cdn.wtf'
  'www.google-analytics.com'
  'cdn.kik.com'
  if config.ENV is config.ENVS.DEV then webpackDevHost

]
stylesSrc = [
  '\'unsafe-inline\''
  if config.ENV is config.ENVS.DEV then webpackDevHost
]
# FIXME: disabled for kik
# app.use helmet.contentSecurityPolicy
#   scriptSrc: scriptSrc
#   stylesSrc: stylesSrc
app.use helmet.xssFilter()

# Some security options are only enabled for the developer site
app.use (req, res, next) ->
  if req.headers.host is config.DEV_HOST
    frameMiddleware = helmet.frameguard()
    hstsMiddleware = helmet.hsts
      # Must be at least 18 weeks to be approved by Google
      # https://hstspreload.appspot.com/
      maxAge: EIGHTEEN_WEEKS_MS
      # required for Google approval, but disabled because of this post
      # http://serverfault.com
      # /questions/482350/can-i-turn-on-hsts-for-1-subdomain
      #includeSubdomains: true
      preload: true # include in Google Chrome
      force: true

    return frameMiddleware req, res, (err) ->
      if err
        return next(err)

      return hstsMiddleware req, res, next
  return next()

app.disable 'x-powered-by'
app.use helmet.noSniff()
app.use helmet.crossdomain()

app.use cookieParser()
app.use useragent.express()
app.use router


# Routes
router.get '/healthcheck', (req, res) ->
  Promise.settle [
      Promise.cast(request.get(config.CLAY_API_URL + '/ping'))
        .timeout HEALTHCHECK_TIMEOUT
      Promise.cast(request.get(config.FC_API_URL + '/ping'))
        .timeout HEALTHCHECK_TIMEOUT
    ]
    .spread (clayApi, flakCannon) ->
      res.json
        clayApi: clayApi.isFulfilled()
        flakCannon: flakCannon.isFulfilled()
        healthy: clayApi.isFulfilled() and flakCannon.isFulfilled()

router.get '/game/:key', (req, res) ->
  log.info 'AGENT ', req.useragent.source
  gameKey = req.params.key

  renderGamePage gameKey
  .then (html) ->
    res.send html
  .catch (err) ->
    log.trace err

    renderHomePage()
    .then (html) ->
      res.send html
    .catch (err) ->
      log.trace err
      res.status(500).send()

router.get '*', (req, res) ->
  log.info 'AGENT ', req.useragent.source
  host = req.headers.host

  # Game Subdomain - 0.0.0.0 used when running tests locally
  if host isnt config.HOST and host isnt config.DEV_HOST and host isnt '0.0.0.0'
    gameKey = host.split('.')[0]

    return renderGamePage gameKey
      .then (html) ->
        res.send html
      .catch (err) ->
        log.trace err
        renderHomePage()
        .then (html) ->
          res.send html
        .catch (err) ->
          log.trace err
          res.status(500).send()

  renderHomePage()
  .then (html) ->
    res.send html
  .catch (err) ->
    log.trace err
    res.status(500).send()

# Cache rendering
renderHomePage = do ->
  page =
    inlineSource: config.ENV is config.ENVS.PROD
    webpackDevHostname: config.WEBPACK_DEV_HOSTNAME
    title: 'Free Games'
    description: 'Play mobile games on your phone for free.
                  We bring you the best mobile web games.'
    keywords: 'mobile games, phone games, free mobile games, mobile web games'
    name: 'Clay.io'
    icon256: '//cdn.wtf/d/images/icons/icon_256.png'
    icon76: '//cdn.wtf/d/images/icons/icon_76.png'
    icon120: '//cdn.wtf/d/images/icons/icon_120.png'
    icon152: '//cdn.wtf/d/images/icons/icon_152.png'
    icon440x280: '//cdn.wtf/d/images/icons/icon_440_280.png'
    iconKik: '//cdn.wtf/d/images/icons/icon_256_orange.png'
    url: 'http://clay.io/'
    canonical: 'http://clay.io'
    distjs: distJs

  rendered = Promise.promisify(dust.render, dust) 'index', page

  -> rendered

renderGamePage = (gameKey) ->

  gameUrl = config.CLAY_API_URL + "/games/findOne?key=#{gameKey}"

  log.info 'GET', gameUrl
  Promise.cast request.get gameUrl
  .timeout API_REQUEST_TIMEOUT
  .then (body) ->
    game = JSON.parse body
    if _.isEmpty game
      throw new Error 'Game not found: ' + gameKey

    page =
      inlineSource: config.ENV is config.ENVS.PROD
      webpackDevHostname: config.WEBPACK_DEV_HOSTNAME
      title: "#{game.name}"
      description: "Play #{game.name}; #{game.description}"
      keywords: "#{game.name}, mobile games,  free mobile games"
      name: "#{game.name} - Clay.io"
      distjs: distJs

      # TODO: (Zoli) This isn't good enough
      icon256: game.iconImage?.versions[0].url or game.icon128Url
      icon76: game.iconImage?.versions[0].url or game.icon128Url
      icon120: game.iconImage?.versions[0].url or game.icon128Url
      icon152: game.iconImage?.versions[0].url or game.icon128Url
      iconKik: game.iconImage?.versions[0].url or game.icon128Url

      # TODO: (Zoli) this should be returned by the server
      icon440x280: "http://cdn.wtf/g/#{game.id}/meta/promo_440.png"
      url: "http://#{game.key}.clay.io"
      canonical: "http://#{game.key}.clay.io"

    Promise.promisify(dust.render, dust) 'index', page

module.exports = app
