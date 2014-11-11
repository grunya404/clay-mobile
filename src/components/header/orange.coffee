z = require 'zorium'

styles = require './orange.styl'

module.exports = class Header
  constructor: ->
    styles.use()

  render: ->
    z 'header.header',
      z 'a.header-logo[href=/]', {config: z.route}
