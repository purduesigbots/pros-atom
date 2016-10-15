path = require 'path'
utils = require './terminal-utilities'

module.exports=
  execute: utils.execute
  executeSync: utils.executeSync
  executeInTerminal: utils.executeInTerminal

  fixProsCommand: (command) ->
    if navigator.platform == 'Win32' and !!process.env['PROS_TOOLCHAIN']
      path.join process.env['PROS_TOOLCHAIN'], command
    else command

  baseCommand: (args...) ->
    return ['pros'].concat(args...)

  lstemplate: (args...) ->
    return @baseCommand().concat(['conduct', 'lstemplate']).concat(args...)

  createNew: (args...) ->
    return @baseCommand().concat(['conduct', 'new']).concat(args...)

  upgrade: (args...) ->
    return @baseCommand().concat(['conduct', 'upgrade']).concat(args...)

  upload: (args...) ->
    return @baseCommand().concat(['flash'].concat(args...))

  terminal: (args...) ->
    return @baseCommand().concat(['terminal'].concat(args...))

  executeParsed: (cb, command, params) ->
    if '--machine-output' not in command
      command.push '--machine-output'
    callback = (c, o) ->
      cb c, JSON.parse e for e in o.split(/\r?\n/).filter(Boolean)
    return utils.execute callback, command, params

  executeParsedSync: (command) ->
    if '--machine-output' not in command
      command.push '--machine-output'
    return JSON.parse e for e in utils.executeSync(command).split(/\r?\n/)
    .filter(Boolean)

  getTemplates: (cb, args...) ->
    @executeParsed cb, @lstemplate(args...), {}

  getTemplatesSync: (args...) ->
    @executeParsedSync(@lstemplate(args...))


  createNewExecute: (cb, args...) ->
    utils.execute cb, @createNew args...

  createNewInTerminal: (args...) ->
    result = utils.executeInTerminal @createNew(args...)
    console.log result
    return result

  upgradeExecute: (cb, args...) ->
    utils.execute cb, @upgrade args...

  upgradeInTerminal: (args...) ->
    utils.executeInTerminal @upgrade args...

  uploadInTerminal: (args...) ->
    return utils.executeInTerminal @upload args...

  serialInTerminal: (args...) ->
    return utils.executeInTerminal @terminal args...

  # wrapper function for scoping reasons
  runInTerminal: (command) ->
    return utils.executeInTerminal command.split ' '
