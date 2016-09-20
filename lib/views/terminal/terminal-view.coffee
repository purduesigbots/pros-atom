{BaseView, View} = require '../base-view'

module.exports =
  TerminalView: class TerminalView extends BaseView
    constructor: ->
      super(__dirname)

      @output = ''
      @hideBtn = @element.querySelector '#pros-terminal-hide'
      @hideBtn.onclick = => @hide()
      @clearBtn = @element.querySelector '#pros-terminal-clear-output'
      @clearBtn.onclick = => @clearOutput()

    show: =>
      @panel ?= atom.workspace.addBottomPanel className: 'PROSTerminal', item: this
      @panel.show()

    updateOutput: =>
      @element.querySelector('.output').innerHTML = @output

    appendOutput: (data) =>
      @output += data
      @updateOutput()

    clearOutput: =>
      @output = ''
      @updateOutput()

    isVisible: =>
      @panel.isVisible()

    register: ->
      super()
