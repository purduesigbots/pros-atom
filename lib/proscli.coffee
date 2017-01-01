{$} = require 'atom-space-pen-views'
cp = require 'child_process'
semver = require 'semver'
statusbar = require './views/statusbar'
{EOL} = require 'os'
brand = require './views/brand'
{setTimeout} = require 'timers'

terminalService = null
currentTerminal = null
cliVer = null

createHtmlSafeString = (str) ->
  temp = document.createElement 'div'
  temp.appendChild document.createTextNode str
  return temp.innerHTML

module.exports =
  prosConduct: (options...) -> ['pros', 'conduct', options...]
  execute: ({cmd, cb, includeStdErr, onstderr, onstdout, nosb}) ->
    if not nosb then statusbar.working()
    outBuf = ''
    errBuf = ''
    # cmd = cmd.join ' '
    env = process.env
    env['LC_ALL'] = 'en_US.utf-8'
    env['LANG'] = 'en_US.utf-8'
    proc = cp.spawn cmd[0], cmd[1..],
      env: env
      cwd: params?.cwd
    proc.on 'error', (err) -> console.log err
    proc.stderr.on 'data', (data) ->
      if includeStdErr
        outBuf += data
      errBuf += data
      onstderr?(data)
    proc.stdout.on 'data', (data) ->
      outBuf += data
      onstdout?(data)
    proc.on 'close', (c, s) ->
      if not nosb then statusbar.stop()
      # console.log errBuf if errBuf
      cb c, outBuf, errBuf
    return proc

  checkCli: ({minVersion, cb, fmt='text', force=false, nosb=false, eol=EOL}) ->
    mapResponse = (fmt, obj) ->
      if fmt == "raw" then return obj
      {code, extra} = obj
      switch code
        when 1
          switch fmt
            when 'html'
              div = $('<div>PROS CLI is out of date. </div>')
              div.append "<span class='status-modified'>(#{extra})</span> "
              div.append "Visit "
              div.append "<a href='http://pros.cs.purdue.edu/upgrading'>pros.cs.purdue.edu/upgrading</a>"
              div.append ' to learn more.'
              return div
            else "PROS CLI is out of date. (#{extra})."
        when 2
          switch fmt
            when 'html' then "PROS CLI was not found on your PATH."
            else "PROS CLI was not found on your PATH."
        when 3
          switch fmt
            when 'html'
              div = $("<div style='text-align: left; white-space: pre-line'></div>")
              div.text "PROS CLI is improperly configured.#{eol}#{extra}"
              return div
            else "PROS CLI is improperly configured."
        else obj.version ? obj.extra
    respond = (obj)->
      statusbar.tooltip?.dispose()
      statusbar.button.removeClass 'has-update'
      if obj.code == 1
        statusbar.button.addClass 'has-update'
      statusbar.updateTooltip()
      cb obj.code, mapResponse fmt, obj

    if cliVer != null and not force then respond cliVer
    @execute cmd: ['where', 'pros'], nosb: nosb, cb: (c, o) =>
      if c != 0
        # console.log o
        cliVer = {code: 2}
        respond cliVer
        return
      @execute cmd: ['pros', '--version'], nosb: nosb, cb: (c, o, e) =>
        if c != 0
          # console.log {c, o, e}
          cliVer = {code: 3, extra: "STDOUT:#{eol}#{o}#{eol}#{eol}ERR:#{eol}#{e}"}
          respond cliVer
          return
        version = /pros, version (.*)/.exec(o)?[1]
        if version is undefined
          # try again one more time, just in case
          @execute cmd: ['pros', '--version'], nosb: nosb, cb: (c, o) ->
            if c != 0
              # console.log o
              cliVer = {code: 3, extra: extra: "STDOUT:#{eol}#{o}#{eol}#{eol}ERR:#{eol}#{e}"}
              respond cliVer
              return
            version = /pros, version(.*)/.exec(o)?[1]
            if !version or semver.lt version, minVersion
              # console.log o
              cliVer = {code: 1, extra: "v#{version} does not meet v#{minVersion}", version: version}
              respond cliVer
              return
            cliVer = {code: 0, extra: version}
            respond cliVer
        else if !version or semver.lt version, minVersion
          # console.log o
          cliVer = {code: 1, extra: "v#{version} does not meet v#{minVersion}", version: version}
          respond cliVer
          return
        cliVer = {code: 0, version: version}
        respond cliVer

  invUpgrade: (callback) ->
    @execute cmd: ['pros', 'upgrade', '--machine-output'], cb: (c, o, e) =>
      if c != 0
        atom.notifications.addError 'Unable to determine how PROS CLI is installed',
            detail: 'You will need to upgrade PROS CLI for your intallation method.'
      else
        cmd = o.split '\n'
        if not atom.inDevMode()
          @execute cmd: cmd, cb: (c, o, e) -> console.log {c, o, e}
        else
          console.log "Running #{cmd.join ' '}"

  executeInTerminal: ({cmd}) ->
    wait = (ms) ->
      start = new Date().getTime()
      continue while new Date().getTime() - start < ms

    if Boolean terminalService
      if not Boolean currentTerminal
        currentTerminal = terminalService.run([])[0].spacePenView
        currentTerminal.statusIcon.style.color = "##{brand.brightGold}"
        currentTerminal.statusIcon.updateName 'PROS CLI'
        currentTerminal.panel.onDidDestroy () -> currentTerminal = null

      currentTerminal.insertSelection '\x03'
      wait 75
      currentTerminal.insertSelection(if navigator.platform is 'Win32' then 'cls' else 'clear')
      wait 75
      currentTerminal.insertSelection command.join ' '
      currentTerminal.focus()
      currentTerminal
    else
      null

  consumeTerminalService: (service) ->
    if Boolean terminalService
      return new Disposable () -> return
    terminalService = service
    return new Disposable () -> terminalService
