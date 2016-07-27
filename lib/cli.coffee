{execute, executeSync, executeInTerminal} = require './terminal-utilities'

module.exports=
  fixProsCommand: (command) ->
    if navigator.platform == 'Win32' and !!process.env['PROS_TOOLCHAIN']
      path.join process.env['PROS_TOOLCHAIN'], command
    else command

  baseCommand: (args...) ->
    return [@fixProsCommand 'pros']

  lstemplate: (args...) ->
    return @baseCommand().concat(['conduct', 'lstemplate']).concat(args...)

  createNew: (args...) ->
    return @baseCommand().concat(['conduct', 'new']).concat(args...)


  executeParsed: (cb, command, params) ->
    if '--machine-output' not in command
      command.push '--machine-output'
    callback = (o) ->
      cb JSON.parse e for e in o.split(/\r?\n/).filter(Boolean)
    return execute callback, command, params

  executeParsedSync: (command) ->
    if '--machine-output' not in command
      command.push '--machine-output'
    return JSON.parse e for e in executeSync(command).split(/\r?\n/)
    .filter(Boolean)


  getTemplates: (cb, args...) ->
    @executeParsed cb, @lstemplate(args...), {}

  getTemplatesSync: (args...) ->
    @executeParsedSync(@lstemplate(args...))

  createNewInTerminal: (args...) ->
    result = executeInTerminal @createNew(args...)
    console.log result
    return result
