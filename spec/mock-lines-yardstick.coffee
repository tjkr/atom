{Point} = require 'text-buffer'

module.exports =
class MockLinesYardstick
  constructor: ({@model, charWidth}) ->
    @setCharacterWidth(charWidth)

  setCharacterWidth: (@charWidth) ->

  pixelPositionForScreenPosition: (screenPosition, clip=true) ->
    screenPosition = Point.fromObject(screenPosition)
    screenPosition = @model.clipScreenPosition(screenPosition) if clip

    targetRow = screenPosition.row
    targetColumn = screenPosition.column
    baseCharacterWidth = @baseCharacterWidth

    top = targetRow * @model.getLineHeightInPixels()
    left = targetColumn * @charWidth

    {top, left}
