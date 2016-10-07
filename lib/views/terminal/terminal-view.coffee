{BaseView, View} = require '../base-view'
{Emitter} = require 'event-kit'

module.exports =
  TerminalView: class TerminalView extends BaseView
    constructor: ->
      super(__dirname)
      @emitter = new Emitter
      @output = ''
      @history = []
      @up = 1
      @hideBtn = @element.querySelector '#pros-terminal-hide'
      @hideBtn.onclick = => @hide()
      @cancelBtn = @element.querySelector '#pros-terminal-cancel-command'
      @clearBtn = @element.querySelector '#pros-terminal-clear-output'
      @clearBtn.onclick = => @clearOutput()
      @inputField = @element.querySelector '#stdin'
      @inputField.onkeypress = (event) =>
        switch event.which
          when 13
            event.preventDefault()
            @emitter.emit 'stdin', @inputField.value
            @history.push @inputField.value
            @inputField.value = ''
            @up = 1
      @inputField.onkeydown = (event) =>
        switch event.which
          when 38
            event.preventDefault()
            if @history.length >= 1
              @inputField.value = @history[@history.length - @up]
              unless @up + 1 > @history.length
                @up++
          when 40
            event.preventDefault()
            if @history.length >= 1
              @inputField.value = @history[@history.length - @up]
              unless @up - 1 < 0
                @up--

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
