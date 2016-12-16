cp = require 'child_process'
{Disposable} = require 'atom'
{TerminalView} = require './views/terminal/terminal-view'

terminalService = null
currentTerminal = null

module.exports =
  consumeRunInTerminal: (service) ->
    if Boolean terminalService
      return new Disposable () -> return
    terminalService = service
    return new Disposable () -> terminalService = null

  execute: (cb, command, params = {}) ->
    outBuf = ''
    cmd = ''
    if navigator.platform != 'Win32'
      cmd = cmd.concat "export LC_ALL=en_US.utf-8;export LANG=en_US.utf-8;"
    cmd = cmd.concat command.join ' '
    proc = cp.exec cmd, { 'encoding': 'utf-8' }
    proc.stderr.on 'data', (data) ->
      if params.includeStdErr then outBuf += data
      params?.onstderr?(data)
    proc.stdout.on 'data', (data) ->
      outBuf += data
      params?.onstdout?(data)
    proc.on 'exit', (c, o, e) ->
      cb c, outBuf or o
    return proc

  executeSync: (command) ->
    cmd = ''
    if navigator.platform != 'Win32'
      cmd = cmd.concat "export LC_ALL=en_US.utf-8;export LANG=en_US.utf-8;"
    cmd = cmd.concat command.join ' '
    proc = cp.execSync cmd, { 'encoding': 'utf-8' }
    return proc.stdout.read()

  executeInTerminal: (command) ->
    wait = (ms) ->
      start = new Date().getTime()
      for num in [0...1e7]
        if ((new Date().getTime() - start) > ms)
          break
    if Boolean(terminalService)
      if Boolean currentTerminal
        currentTerminal.insertSelection '\x03'
        wait 75 # hard code waits to allow commands to be executed
        currentTerminal.insertSelection(if navigator.platform is 'Win32' then 'cls' else 'clear')
        wait 75
        currentTerminal.insertSelection command.join ' '
        currentTerminal.focus()
      else
        currentTerminal = terminalService.run([command.join ' '])[0].spacePenView
        currentTerminal.statusIcon.style.color = '#cca352'
        currentTerminal.statusIcon.updateName 'PROS CLI'
        currentTerminal.panel.onDidDestroy () -> currentTerminal = null
      return currentTerminal
    else
      return null
