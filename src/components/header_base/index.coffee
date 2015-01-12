z = require 'zorium'

styles = require './index.styl'

module.exports = class HeaderBase
  constructor: ({logoUrl, homeUrl, links}) ->
    styles.use()

    @state = z.state {logoUrl, homeUrl, links}

  render: ({logoUrl, homeUrl, links}) ->
    z '.z-header-base',
      z '.l-content-container.l-flex.l-vertical-center',
        z.router.a ".logo[href=#{homeUrl}]",
          z "img[src=#{logoUrl}]"
        z 'nav.navigation',
          z 'ul',
          _.map links, (link) ->
            z "li#{if link.isSelected then '.is-selected' else ''}",
              z 'div.l-flex.l-vertical-center',
                if link.isExternal
                  z "a[href=#{link.url}][target=_blank]",
                    {onclick: link.onclick},
                    link.text
                else
                  z.router.a "[href=#{link.url}]",
                    {onclick: link.onclick},
                    link.text
