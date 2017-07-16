{$} = require 'atom-space-pen-views'
{Disposable} = require 'atom'
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
    if atom.config.get('pros.locale') != "inherit"
      env['LC_ALL'] = atom.config.get 'pros.locale'
      env['LANG'] = atom.config.get 'pros.locale'
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
    which = ['which', 'pros']
    if navigator.platform is 'Win32' then which[0] = 'where'
    @execute cmd: which, nosb: nosb, cb: (c, o) =>
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
        # coffeelint: disable=max_line_length
        version = /pros, version \b(v?(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)(?:-[\da-z\-]+(?:\.[\da-z\-]+)*)?(?:\+[\da-z\-]+(?:\.[\da-z\-]+)*)?)\b/.exec(o)?[1]
        # coffeelint: enable=max_line_length
        if version is undefined
          # try again one more time, just in case
          @execute cmd: ['pros', '--version'], nosb: nosb, cb: (c, o) ->
            if c != 0
              # console.log o
              cliVer = {code: 3, extra: "STDOUT:#{eol}#{o}#{eol}#{eol}ERR:#{eol}#{e}"}
              respond cliVer
              return
            # coffeelint: disable=max_line_length
            version = /pros, version \b(v?(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)(?:-[\da-z\-]+(?:\.[\da-z\-]+)*)?(?:\+[\da-z\-]+(?:\.[\da-z\-]+)*)?)\b/.exec(o)?[1]
            # coffeelint: enable=max_line_length
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
    @execute cmd: ['pros', 'upgrade', '--machine-output'], cb: (c, o, e) ->
      if c != 0
        atom.notifications.addError 'Unable to determine how PROS CLI is installed',
            detail: 'You will need to upgrade PROS CLI for your intallation method.'
      else
        cmd = o.split('\n').filter(Boolean).map Function.prototype.call, String.prototype.trim
        if navigator.platform == "Win32" and cmd.length == 3  # fix for calling upgrader on Windows
          cmd[1] = "/checknow"
          cmd[2] = "/reducedgui"
        if not atom.inDevMode()
          cp.execFile cmd[0], cmd[1..]
        else
          console.log "Running #{cmd.join ' '}"

  executeInTerminal: ({cmd}) ->
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
        currentTerminal.insertSelection cmd.join ' '
        currentTerminal.focus()
      else
        currentTerminal = terminalService.run([cmd.join ' '])[0].spacePenView
        currentTerminal.statusIcon.style.color = '#cca352'
        currentTerminal.statusIcon.updateName 'PROS CLI'
        currentTerminal.panel.onDidDestroy () -> currentTerminal = null
      return currentTerminal
    else
      return null

  consumeTerminalService: (service) ->
    if Boolean terminalService
      return new Disposable () -> return
    terminalService = service
    return new Disposable () -> terminalService
