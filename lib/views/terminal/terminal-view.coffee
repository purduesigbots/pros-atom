{BaseView, View} = require '../base-view'

module.exports =
  TerminalView: class TerminalView extends BaseView
    constructor: ->
      super(__dirname)

      @output = ''
      @hideBtn = @element.querySelector '#pros-terminal-hide'
      @hideBtn.onclick = => @hide()
      @cancelBtn = @element.querySelector '#pros-terminal-cancel-command'
      @clearBtn = @element.querySelector '#pros-terminal-clear-output'
      @clearBtn.onclick = => @clearOutput()
      @element.querySelector '.output'

    show: =>
      @panel ?= atom.workspace.addBottomPanel className: 'PROSTerminal', item: this
      @panel.show()

    updateOutput: =>
      out = @element.querySelector '.panel-container'
      out.innerHTML = @output
      out.scrollTop = out.scrollHeight

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
