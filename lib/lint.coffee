{CompositeDisposable} = require 'atom'
config = require './config'
commandExists = require 'command-exists'
fs = require 'fs'
linthelp = require 'atom-linter'
path = require 'path'
{execute} = require './proscli'
utils = require './utils'

subscriptions = null
grammars = ['C', 'C++']

module.exports =
  messages: {}
  linter: undefined
  registry: undefined

  activate: () ->
    subscriptions?.dispose()
    subscriptions = new CompositeDisposable
    if module.exports.registry then module.exports.consumeLinter module.exports.registry


  deactivate: () ->
    subscriptions?.dispose()

  getValidGrammar: (editor) ->
    grammar_name = editor.getGrammar().name
    if grammar_name == 'C' then 'C' \
    else if grammar_name.indexOf 'C++' >= 0 then 'C++' \
    else undefined

  lint: (editor, lintable_file, real_file) ->
    cwd = utils.findRoot atom.workspace.getActiveTextEditor().getPath()

    settings = config.settings real_file

    command = if !!process.env['PROS_TOOLCHAIN'] then \
      path.join process.env['PROS_TOOLCHAIN'], 'bin', 'arm-none-eabi-g++' \
      else 'arm-none-eabi-g++'
    if navigator.platform == 'Win32'
      command += '.exe'

    commandExists command, (err, commandDoesExist) =>
      if err
        atom.notifications.addError 'pros: Error trying to find command',
        {
          detail: 'Error from command-exists: ' + err
        }
      else if commandDoesExist or fs.statSync(command).isFile()
        args = []
        grammar_type = @getValidGrammar editor
        flags = if grammar_type = 'C++' then settings.lint.default_Cpp_flags \
          else if grammar_type = 'C' then settings.lint.default_C_flags
        args = args.concat flags.split ' '
        if settings.lint.error_limit >= 0
          args.push "-fmax-errors=#{settings.lint.error_limit}"
        for include in settings.include_paths
          args.push "-I#{path.join cwd, include}"
        if settings.lint.suppress_warnings then args.push '-w'
        args.push lintable_file
        if path.extname(editor.getPath()).toLowerCase() in ['.h' ,'.hpp']
          args.push '-fsyntax-only'
        else
          temp = (require 'tempfile') path.extname editor.getPath()
          args.push "-o #{temp}"
        args = args.filter Boolean
        execute {
          cmd: [command, args...],
          includeStdErr: true,
          cb: (c, o, e) ->
            regex = "(?<file>.+):(?<line>\\d+):(?<col>\\d+):\\s*\\w*\\s*" +
              "(?<type>(error|warning|note)):\\s*(?<message>.*)"
            msgs = linthelp.parse o, regex
            msgs.filter((entry) -> entry.filePath == lintable_file) \
              .forEach (entry) -> entry.filePath = real_file
            module.exports.messages[real_file] = msgs
            module.exports.linter?.setMessages?(msgs)
        }
      else
        atom.notifications.addError 'pros: Error trying to find command',
          {
            detail: "Couldn't find #{command} in environment"
          }

  lintOnSave: () ->
    editor = atom.workspace.getActiveTextEditor()
    if not editor or editor.getGrammar().name not in grammars then return
    module.exports.lint editor, editor.getPath(), editor.getPath()

  lintOnTheFly: () ->
    editor = atom.workspace.getActiveTextEditor()
    if not editor? or editor.getGrammar().name not in grammars then return
    if not config.settings().lint.on_the_fly then return
    temp = (require 'tempfile') path.extname editor.getPath()
    (require 'fs-extra').outputFile temp, editor.getText(), () ->
      module.exports.lint editor, temp, editor.getPath()

  consumeLinter: (registry) ->
    module.exports.registry = registry
    subscriptions?.dispose()
    subscriptions = new CompositeDisposable
    module.exports.linter = registry.register({name: 'PROS GCC Linter'})
    subscriptions.add module.exports.linter
    atom.workspace.observeTextEditors (editor) ->
      subscriptions.add editor.onDidSave module.exports.lintOnSave
      # TODO: onDidStopChanging is a little to agressive with updates
      subscriptions.add editor.onDidStopChanging module.exports.lintOnTheFly
