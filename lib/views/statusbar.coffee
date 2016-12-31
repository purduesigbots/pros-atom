{CompositeDisposable} = require 'atom'
{$, View} = require 'atom-space-pen-views'

class StatusBar extends View
  @content: ->
    @div class: 'pros-status-bar inline-block', =>
      # coffeelint: disable=max_line_length
      @button class: 'btn btn-default', outlet: 'button',
        => @raw "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\">
  <defs>
    <g id=\"logo\">
      <polygon points=\"79 41.4 94.2 54.5 50.1 93 50.1 93 50 93 6.1 54.8 21.3 41.5 50.1 83.7 \"/>
      <polygon points=\"28.2 28.2 29 29.7 71.3 29.7 72.1 28.2\"/>
      <polygon points=\"38.1 56.5 33.1 42 18.9 34.1 \"/>
      <polygon points=\"62.2 56.7 67.3 42 81.2 34.3 \"/>
      <path d=\"M50.1 8.6L12.8 25.5h13.4l2.8 4.3H71.3l2.8-4.3H87.5L50.1 8.6zM53.1 18.9l-2.9 1.5 -2.9-1.5v-2.9l2.9-1.5 2.9 1.5V18.9z\"/>
      <path d=\"M80.5 34.1H19.8l0.1 0.1 18.5 2.8 -0.3 19.5 -2.4-2.8L49.4 70.6V52.3c0-0.3 0.3-0.6 0.6-0.6h0.3c0.3 0 0.6 0.3 0.6 0.6V70.6L62.2 56.6l-0.1 0.1 -0.3-19.6 18.4-2.6L80.5 34.1zM50.1 48.8c-0.6 0-1.2-0.5-1.2-1.2 0-0.6 0.5-1.2 1.2-1.2 0.6 0 1.2 0.5 1.2 1.2C51.3 48.2 50.8 48.8 50.1 48.8zM50.1 43.8c-0.6 0-1.2-0.5-1.2-1.2 0-0.6 0.5-1.2 1.2-1.2 0.6 0 1.2 0.5 1.2 1.2C51.3 43.3 50.8 43.8 50.1 43.8zM50.1 38.7c-0.6 0-1.2-0.5-1.2-1.2s0.5-1.2 1.2-1.2c0.6 0 1.2 0.5 1.2 1.2S50.8 38.7 50.1 38.7z\"/>
    </g>
  </defs>
  <use xlink:href=\"#logo\"/>
  <g id='overlay'><use xlink:href='#logo'/></g>
</svg>"
      # coffeelint: enable=max_line_length

  tooltip: null
  btn: null
  initialize: () ->
    @button.onclick = ->
      atom.commands.dispatch atom.views.getView(atom.workspace.getActivePane()),
        'PROS:Toggle-PROS'
    @btn = @button[0] # cache the lookup
    @tooltip = atom.tooltips.add @button, title: 'Click to disable PROS editor components'

  attach: (provider) -> provider.addRightTile(item: this, priority: -10)

  count: 0
  working: () ->
    if @count == 0
      @button.addClass 'animate'
      @tooltip?.dispose()
      @tooltip = atom.tooltips.add @button,
        title: 'Running PROS CLI tasks in the background.<br/>Click to disable PROS editor components'
    @count += 1

  stop: (uid=0) ->
    @count -= 1
    if @count == 0
      @button.removeClass 'animate'
      @tooltip?.dispose()
      @tooltip = atom.tooltips.add @button, title: 'Click to disable PROS editor components'

module.exports = new StatusBar
