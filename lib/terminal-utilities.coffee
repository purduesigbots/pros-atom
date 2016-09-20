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

  executeInTerminal: (command) ->
    terminal = (panel.item for panel in atom.workspace.getBottomPanels()\
    when panel.className is 'PROSTerminal')[0]

    terminal.clearOutput()
    terminal.appendOutput "<p>#&gt; #{command.join ' '}</p>"

    if not terminal.isVisible() then terminal.toggle()

    cb = (c, o) ->
      terminal.appendOutput "<p>Process exited with code #{c}.</p>"

    out = (data) ->
      terminal.appendOutput "<p>#{data.replace '\n','<br/>'}</p>"

    err = (data) ->
      terminal.appendOutput "<p>#{data.replace '\n', '<br/>'}</p>"

    @execute(cb, command, { includeStdErr: true, onstdout: out, onstderr: err })
