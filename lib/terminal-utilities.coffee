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

  executeInTerminal: (command) =>
    terminal =
    if not terminal.isVisible() then terminal.toggle()

    @execute((cb: (code, outBuf) ->
      terminal.content += outBuf
      terminal.content += "\nProcess exited with code #{code}"
    ), command, includeStdErr: true)
