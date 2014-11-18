_ = require 'lodash'
should = require('clay-chai').should()

GameBox = require 'components/game_box'

MockGame = require '../../_models/game'

describe 'GameBox', ->

  it 'sets image size', ->
    $ = new GameBox({game: MockGame, iconSize: 100}).render()

    _.find($.children, {tagName: 'img'}).properties.width.should.be 100
    _.find($.children, {tagName: 'img'}).properties.height.should.be 100
