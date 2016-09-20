{BaseView, View} = require '../base-view'

module.exports =
  TerminalView: class TerminalView extends BaseView
    constructor: ->
      super(__dirname)

      @hideBtn = @element.querySelector '#pros-terminal-hide'
      @hideBtn.onclick = => @hide()

    show: =>
      @panel ?= atom.workspace.addBottomPanel item: this
      @panel.show()

    clearOutput: =>
      @output = ''

    isVisible: =>
      @panel.isVisible()

    register: ->
      super()
