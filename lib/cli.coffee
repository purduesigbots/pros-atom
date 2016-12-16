path = require 'path'
utils = require './terminal-utilities'
semver = require 'semver'

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

  infoProject: (args...) ->
    return @baseCommand().concat(['conduct', 'info-project']).concat(args...)

  addLib: (args...) ->
    return @baseCommand().concat(['conduct', 'new-lib']).concat(args...)

  executeParsed: (cb, command, params) ->
    if '--machine-output' not in command
      command.push '--machine-output'
    callback = (c, o) ->
      cb c, JSON.parse e for e in o?.split(/\r?\n/).filter(Boolean)
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

  projectInfo: (cb, args...) ->
    @executeParsed cb, @infoProject(args...), {}

  projectInfoSync: (cb, args...) ->
    @executeParsedSync @infoProject args...

  addLibraryExecute: (cb, args...) ->
    utils.execute cb, @addLib args...

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

  checkCli: (minVersion, cb) ->
    # wait... maybe environment not yet properly loaded yet
    process.nextTick ->
      utils.execute(((c, o) ->
        if c != 0
          console.log o
          cb 2, 'PROS CLI was not found on your PATH.'
        else
          utils.execute(((c, o) ->
            if c != 0
              console.log o
              cb 3, 'PROS CLI is improperly configured.'
            else
              version = /pros, version (.*)/g.exec(o)?[1]
              if not version or semver.lt(version, minVersion)
                if version is undefined
                  # it's posssible that it failed by chance... try again
                  utils.execute(((c, o) ->
                    if c != 0
                      console.log o
                      cb 3, 'PROS CLI is improperly configured.'
                    else
                      version = /pros, version (.*)/g.exec(o)?[1]
                      if not version or semver.lt(version, minVersion)
                        console.log o
                        cb 1, "PROS CLI is out of date. (#{version} does not meet #{minVersion})"
                      else
                        cb 0, version
                  ), ['pros', '--version'])
                console.log o
                cb 1, "PROS CLI is out of date. (#{version} does not meet #{minVersion})"
              else
                cb 0, version
          ), ['pros', '--version'])
        ), ['where', 'pros'])
