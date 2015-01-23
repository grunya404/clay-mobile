EnvironmentService = require './environment'
User = require '../models/user'
Modal = require '../models/modal'
GooglePlayAdModal = require '../components/google_play_ad_modal'
GooglePlayAdModalFlat = require '../components/google_play_ad_modal/flat'

FIRST_DISPLAY_VISIT_COUNT = 1
SECOND_DISPLAY_VISIT_COUNT = 5
NTH_DISPLAY_VISIT_COUNT = 10

# all methods should return promises for consistency
class GooglePlayAdService
  constructor: ->
    @hasAdModalBeenShown = false

  showAdModal: =>
    User.getExperiments().then ({googlePlayAdType}) =>
      googlePlayAdModalComponent = switch googlePlayAdType
        when 'flat' then new GooglePlayAdModalFlat()
        else new GooglePlayAdModal()
      Modal.openComponent(
        component: googlePlayAdModalComponent
      )
      @hasAdModalBeenShown = true

  shouldShowAdModal: =>
    if @shouldShowAds() and not @hasAdModalBeenShown
      User.getVisitCount().then (visitCount) ->
        return visitCount is FIRST_DISPLAY_VISIT_COUNT or
          visitCount is SECOND_DISPLAY_VISIT_COUNT or
          not (visitCount % NTH_DISPLAY_VISIT_COUNT)
    else
      Promise.resolve false

  shouldShowAds: ->
    return EnvironmentService.isAndroid() and
           not EnvironmentService.isClayApp()

module.exports = new GooglePlayAdService()
