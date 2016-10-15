{BaseView, View} = require '../base-view'
{Emitter} = require 'event-kit'
cp = require 'child_process'

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
          when 13 # handle enter key
            event.preventDefault()
            @emitter.emit 'stdin', @inputField.value
            @history.push @inputField.value
            @inputField.value = ''
            @up = 1
      @inputField.onkeydown = (event) => # handle up/down keys
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

    createDiv: (text, classes) ->
      "<div class=\"#{classes}\">#{text}</div>"

    execute: (command) =>
      # console.log execute
      @clearOutput()
      @appendOutput \
        @createDiv "#&gt; #{command.join ' '}", "pros-terminal-command"


      cb = (c, o) =>
        @appendOutput \
          @createDiv "Process exited with code #{c ? 0}", "pros-terminal-terminus"

      out = (data) =>
        @appendOutput "#{data}"

      err = (data) =>
        @appendOutput \
              @createDiv "#{data}", "pros-terminal-stderr"

      outBuf = ''
      cmd = ''
      if navigator.platform != 'Win32'
        cmd = cmd.concat "export LC_ALL=en_US.utf-8;export LANG=en_US.utf-8;"
      cmd = cmd.concat command.join ' '
      proc = cp.exec cmd, { 'encoding': 'utf-8' }
      proc.stderr.on 'data', (data) -> err data
      proc.stdout.on 'data', (data) ->
        outBuf += data
        out data
      proc.on 'exit', (c, o, e) ->
        cb c, outBuf

      if not @isVisible() then @toggle()
      @cancelBtn.onclick = =>
        console.log "Killing #{command.join ' '}"
        proc.stdin.end('\x1b\n')
