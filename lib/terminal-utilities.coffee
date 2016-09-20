cp = require 'child_process'
{Disposable} = require 'atom'
{TerminalView} = require './views/terminal/terminal-view'

module.exports =

  execute: (cb, command, params = {}) ->
    outBuf = ''
    proc = cp.exec command.join ' ', { 'encoding': 'utf-8' }
    proc.stderr.on 'data', (data) ->
      if params.includeStdErr then outBuf += data
      params?.onstderr?(data)
    proc.stdout.on 'data', (data) ->
      outBuf += data
      params?.onstdout?(data)
    proc.on 'exit', (c, o, e) ->
      cb c, outBuf
    return proc

  executeSync: (command) ->
    proc = cp.execSync command.join ' ', { 'encoding': 'utf-8' }
    return proc.stdout.read()

  createDiv: (text, classes) ->
    "<div class=\"#{classes}\">#{text}</div>"

  executeInTerminal: (command) ->
    terminal = (panel.item for panel in atom.workspace.getBottomPanels()\
    when panel.className is 'PROSTerminal')[0]

    terminal.clearOutput()
    terminal.appendOutput \
      @createDiv "#&gt; #{command.join ' '}", "pros-terminal-command"

    if not terminal.isVisible() then terminal.toggle()

    cb = (c, o) =>
      terminal.appendOutput \
        @createDiv "Process exited with code #{c}", "pros-terminal-terminus"

    out = (data) ->
      terminal.appendOutput "#{data}"

    err = (data) =>
      terminal.appendOutput \
        @createDiv "#{data}", "pros-terminal-stderr"

    @execute(cb, command, { includeStdErr: true, onstdout: out, onstderr: err })
