{$} = require 'atom-space-pen-views'
cp = require 'child_process'
semver = require 'semver'

brand = require './views/brand'
{setTimeout} = require 'timers'

terminalService = null
currentTerminal = null

createHtmlSafeString = (str) ->
  temp = document.createElement 'div'
  temp.appendChild document.createTextNode str
  return temp.innerHTML

module.exports =
  prosConduct: (options...) -> ['pros', 'conduct', options...]
  execute: ({cmd, cb, includeStdErr=false, onstderr, onstdout}) ->
    outBuf = ''
    errBuf = ''
    # cmd = cmd.join ' '
    env = process.env
    env['LC_ALL'] = 'en_US.utf-8'
    env['LANG'] = 'en_US.utf-8'
    proc = cp.spawn cmd[0], cmd[1..],
      env: env
      cwd: params?.cwd
    proc.stderr.on 'data', (data) ->
      outBuf += data if includeStdErr
      errBuf += data
      onstderr?(data)
    proc.stdout.on 'data', (data) ->
      outBuf += data
      onstdout?(data)
    proc.on 'close', (c, s) ->
      console.log errBuf if errBuf
      # console.log {cmd, cb}
      cb c, outBuf, errBuf
    return proc

  checkCli: ({minVersion, cb, fmt='text'}) ->
    mapResponse = ({code, fmt, extra}) ->
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
              div = $('<div>PROS CLI is improperly configured.<br/></div>')
              for line in extra.split '\n'
                div.append document.createTextNode line
                div.append '<br/>'
              return div
            else "PROS CLI is improperly configured."
        else ""

    @execute cmd: ['where', 'pros'], cb: (c, o) =>
      if c != 0
        console.log o
        cb 2, mapResponse code: 2, fmt: fmt
        return
      @execute cmd: ['pros', '--version'], cb: (c, o, e) =>
        if c != 0
          console.log {c, o, e}
          cb 3, mapResponse code: 3, fmt: fmt, extra: "STDOUT:\n#{o}\n\nERR:\n#{e}"
          return
        version = /pros, version (.*)/.exec(o)?[1]
        if version is undefined
          # try again one more time, just in case
          @execute cmd: ['pros', '--version'], cb: (c, o) ->
            if c != 0
              console.log o
              cb 3, mapResponse code: 3, fmt: fmt, extra: "STDOUT:\n#{o}\n\nERR:\n#{e}"
              return
            version = /pros, version(.*)/.exec(o)?[1]
            if not version or semver.lt version, minVersion
              console.log o
              cb 1, mapResponse code: 1, fmt: fmt, extra: "v#{version} does not meet v#{minVersion}"
              return
            cb 0, version
        else if not version or semver.lt version, minVersion
          console.log o
          cb 1, mapResponse code: 1, fmt: fmt, extra: "v#{version} does not meet v#{minVersion}"
          return
        cb 0, version

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
