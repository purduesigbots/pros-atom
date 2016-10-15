cp = require 'child_process'
{Disposable} = require 'atom'
{TerminalView} = require './views/terminal/terminal-view'

terminalService = null
currentTerminal = null
module.exports =
  statusBar: null
  consumeRunInTerminal: (service) =>
    if Boolean terminalService
      return new Disposable () -> return
    terminalService = service
    console.log terminalService
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
      cb c, outBuf
    return proc

  executeSync: (command) ->
    cmd = ''
    if navigator.platform != 'Win32'
      cmd = cmd.concat "export LC_ALL=en_US.utf-8;export LANG=en_US.utf-8;"
    cmd = cmd.concat command.join ' '
    proc = cp.execSync cmd, { 'encoding': 'utf-8' }
    return proc.stdout.read()

  executeInTerminal: (command) ->
    # terminalService.destroyTerminalView currentTerminal
    if Boolean(terminalService)
      if Boolean currentTerminal
        currentTerminal.insertSelection '\x03'
        currentTerminal.insertSelection if navigator.platform is 'Win32' then 'cls' else 'clear'
        currentTerminal.insertSelection command.join ' '
        currentTerminal.focus()
      else
        currentTerminal = terminalService.run([command.join ' '])[0].spacePenView
        currentTerminal.statusIcon.style.color = '#cca352'
        currentTerminal.statusIcon.updateName 'PROS CLI'
      return currentTerminal
    else
      return null
