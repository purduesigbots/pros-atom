{BaseView, View} = require '../base-view'

module.exports =
  TerminalView: class TerminalView extends BaseView
    constructor: ->
      super(__dirname)

      @output = ''
      @hideBtn = @element.querySelector '#pros-terminal-hide'
      @hideBtn.onclick = => @hide()
      @cancelBtn = @element.querySelector '#pros-terminal-cancel-command'
      @cancelBtn.onclick = => @cancelCmd()
      @clearBtn = @element.querySelector '#pros-terminal-clear-output'
      @clearBtn.onclick = => @clearOutput()

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

    cancelCmd: ->
      # TODO: add ability to cancel command

    isVisible: =>
      @panel.isVisible()

    register: ->
      super()
