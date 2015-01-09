z = require 'zorium'
log = require 'clay-loglevel'

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
      email: new InputBlock {
        label: 'Email'
        input: new InputText {value: '', theme: '.theme-full-width'}
      }
      password: new InputBlock {
        label: 'Password'
        input: new InputPassword {value: '', theme: '.theme-full-width'}
      }

  login: (e) =>
    e?.preventDefault()
    email = @state().email.input.getValue()
    password = @state().password.input.getValue()
    User.setMe User.loginBasic {email, password}
    .then ({id}) ->
      Developer.find {ownerId: id }
    .then (developers) ->
      if developers.length is 0
        Developer.create()
    .then ->
      z.router.go '/developers'
    .catch log.trace

  render: =>
    z 'div.z-dev-login',
      z 'h1', 'Sign In'
      z 'div.friendly-message', 'Hey, good to see you again.'
      z 'form',
        {onsubmit: @login},
        @state().email
        @state().password
        # TODO (Austin) forgot password, whenever someone aks for it
        z 'button.button-secondary.sign-in', 'Sign In'