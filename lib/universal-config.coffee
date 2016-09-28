# scopes for univesal config are: atom, project, directory

path = require 'path'
fs = require 'fs'

handlers =
  atom: (config, identifier, options) ->
    config = module.exports.filterConfig config, 'atom'
    obj = {}
    for property, value of config
      obj[property] = atom.config.get "#{identifier}.#{property}"
    return obj

  project: (config, identifier, options) ->
    config = module.exports.filterConfig config, 'project'
    obj = {}
    project = atom.project.relativizePath(editor.getPath())
    editor = atom.workspace.getActiveTextEditor()
    return unless editor
    if !!!project
      return obj
    file = path.join project, (options?.project?.filename or '.atom-config')
    try
      fs.accessSync file, fs.F_OK | fs.R_OK
    catch e  # file doesn't exist or some other exception... just ignore
      return obj
    obj = JSON.parse fs.readFileSync file
    for property, value of obj
      if not config.hasOwnProperty property
        delete obj[property]
    return obj

  directory: (config, identifier, options) ->
    cofig = module.exports.filterConfig config, 'directory'
    obj = {}
    filename = options?.directory?.filename or '.atom-config'
    return unless atom.workspace.getActiveTextEditor()
    dir = atom.workspace.getActiveTextEditor().getPath()
    for [1...(options?.directory?.recurseTimes or 5)]
      dir = path.dirname dir
      try
        pat = path.join dir, filename
        fs.accessSync pat, fs.F_OK | fs.R_OK
        obj = JSON.parse fs.readFileSync pat
        break
      catch e
        continue
    for property, value of obj
      if not config.hasOwnProperty property
        delete obj[property]
    return obj

module.exports =
  addHandler: (scope, func) ->
    @handlers[scope] = func

  loadConfig: (config, scopes, identifier, options) ->
    if not scopes
      scopes = ['atom', 'project', 'directory']
    cfg = {}
    for scope in scopes
      if handlers.hasOwnProperty scope
        for prop, value of handlers[scope] config, identifier, options
          cfg[prop] = value
    return cfg

  filterConfig: (config, scope) ->
    cfg = {}
    for property, value of config
      # if no scope, assume it's there
      if not value.hasOwnProperty('scope') or value.scope.indexOf(scope) >= 0
        cfg[property] = value
        if value.type is 'object'
          cfg[property].properties = arguments.callee value.properties, scope
    return cfg
