z = require 'zorium'
log = require 'clay-loglevel'

VerticalDivider = require '../../components/vertical_divider'
InputBlock = require '../input_block'
InputText = require '../input_text'
InputPassword = require '../input_password'
User = require '../../models/user'
Developer = require '../../models/developer'

styles = require './index.styl'

module.exports = class DevLogin
  constructor: ->
    styles.use()

    @state = z.state
      emailBlock: new InputBlock {
        label: 'Email'
        input: new InputText {value: '', theme: '.theme-full-width'}
      }
      passwordBlock: new InputBlock {
        label: 'Password'
        input: new InputPassword {value: '', theme: '.theme-full-width'}
      }
      applyEmailBlock: new InputBlock {
        label: 'Email'
        input: new InputText {value: '', theme: '.theme-full-width'}
      }
      applyGameUrlBlock: new InputBlock {
        label: 'Game URL'
        input: new InputText {value: '', theme: '.theme-full-width'}
      }
      verticalDivider: new VerticalDivider()

  login: (e) =>
    e?.preventDefault()
    email = @state().emailBlock.input.getValue()
    password = @state().passwordBlock.input.getValue()
    User.setMe User.loginBasic {email, password}
    .then ({id}) ->
      Developer.find {ownerId: id }
    .then (developers) ->
      if developers.length is 0
        Developer.create()
    .then ->
      z.router.go '/developers'
    .catch (err) ->
      log.trace err
      error = JSON.parse err._body
      # TODO: (Austin) better error handling UX
      alert error.detail
    .catch log.trace

  apply: (e) =>
    null # FIXME

  render: (
    {
      emailBlock
      passwordBlock
      applyEmailBlock
      applyGameUrlBlock
      verticalDivider
    }
  ) ->
    z 'div.z-dev-login',
      z 'div.banner',
        z 'div.l-flex.l-vertical-center',
          z 'div.content',
            z 'div', 'Welcome, developers.'
            z 'div', 'Sign in to start publishing'

      z 'div.login-apply.l-content-container.l-flex',
        z 'div.login',
          z 'h1', 'Sign In'
          z 'div.friendly-message', 'Hey, good to see you again.'
          z 'form',
            {onsubmit: @login},
            emailBlock
            passwordBlock
            # TODO (Austin) forgot password, whenever someone aks for it
            z 'button.button-secondary.sign-in-button', 'Sign In'
          z 'div.tos',
            'By signup up for Clay.io, you agree to our '
            z 'a[href=/tos]', 'Terms of Service'

        verticalDivider

        z 'div.apply',
          z 'h1', 'Request an invite'
          z 'div.friendly-message',
            z 'p',
              'We aim to provide the best possible support to every developer on
              Clay.'
            z 'p', "To do this we're limiting signups for now.
              Share your awesome game with us and we'll send you an
              invite when we can."

          z 'form',
            {onsubmit: @apply},
            applyEmailBlock
            applyGameUrlBlock
            z 'button.button-primary.apply-button', 'Apply!'

      z 'div.player-message',
        z 'div.l-content-container.content',
          z 'h1', 'Are you a player?'
          z 'div', 'Download our Android app or visit Clay on Kik or your
                    web browser to play.'
          z 'div.links',
            z 'a.google-play[target=_blank][href=
              http://play.google.com/store/apps/details?id=com.clay.clay]',
              z 'img' +
                '[src=//cdn.wtf/d/images/google_play/google_play_get_it.svg]'
            z 'a.kik[href=http://kik.com][target=_blank]',
              z 'img[src=//cdn.wtf/d/images/kik/kik_logo.svg]'
