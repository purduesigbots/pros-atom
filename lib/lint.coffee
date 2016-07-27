{CompositeDisposable} = require 'atom'
config = require './config'
commandExists = require 'command-exists'
fs = require 'fs'
linthelp = require 'atom-linter'
path = require 'path'
terminal = require './terminal-utilities'

module.exports =
  messages: {}
  linter: undefined

  activate: () =>
    @grammars = ['C', 'C++']
    @subscriptions = new CompositeDisposable

  deactivate: () =>
    @subscriptions.dispose()

  getValidGrammar: (editor) ->
    grammar_name = editor.getGrammar().name
    if grammar_name == 'C' then 'C' \
    else if grammar_name.indexOf 'C++' >= 0 then 'C++' \
    else undefined

  lint: (editor, lintable_file, real_file) ->
    # get current working directory
    cwd = atom.project.getPaths()[0]
    if !cwd
      editor = atom.workspace.getActivePaneItem()
      if editor
        temp_file = editor.buffer.file
        if temp_file
          cwd = temp_file.getParent().getPath()
    cwd = if cwd then cwd else ''

    settings = config.settings real_file

    command = if !!process.env['PROS_TOOLCHAIN'] then \
      path.join process.env['PROS_TOOLCHAIN'], 'bin', 'arm-none-eabi-g++' \
      else 'arm-none-eabi-g++'
    if navigator.platform == 'Win32'
      command += '.exe'

    handleLintOutput = (output) ->
      regex = "(?<file>.+):(?<line>\\d+):(?<col>\\d+):\\s*\\w*\\s*" +
        "(?<type>(error|warning|note)):\\s*(?<message>.*)"
      msgs = linthelp.parse output, regex
      msgs.filter((entry) -> entry.filePath in lintable_file) \
        .forEach (entry) -> entry.FilePath = real_file
      module.exports.messages[real_file] = msgs
      module.exports.linter?.setMessages?(msgs)

    commandExists command, (err, commandDoesExist) =>
      if err
        atom.notifications.addError 'purdueros: Error trying to find command',
        {
          detail: 'Error from command-exists: ' + err
        }
      else if commandDoesExist or fs.statSync(command).isFile()
        command = "\"#{command}\""
        args = []
        grammar_type = @getValidGrammar editor
        flags = if grammar_type = 'C++' then settings.lintDefaultCppFlags \
          else if grammar_type = 'C' then settings.lintDefaultCFlags
        args = args.concat flags.split ' '
        if settings.lintErrorLimit >= 0
          args.push "-fmax-errors=#{settings.lintErrorLimit}"
        for include in settings.lintIncludePaths
          args.push "-I\"#{path.join cwd, include}\""
        if settings.lintSuppressWarnings then args.push '-w'
        args.push "\"#{lintable_file}\""
        args = args.filter Boolean
        terminal.execute handleLintOutput, [command].concat(args), {includeStdErr: true}
      else
        atom.notifications.addError 'purdueros: Error trying to find command',
          {
            detail: "Couldn't find #{command} in environment"
          }

  lintOnSave: () =>
    editor = atom.workspace.getActiveTextEditor()
    if not editor? or editor.getGrammar().name not in @grammars then return
    module.exports.lint editor, editor.getPath(), editor.getPath()

  consumeLinter: (indieRegistry) =>
    module.exports.linter = indieRegistry.register({name: 'PROS GCC Linter'})
    @subscriptions.add module.exports.linter
    atom.workspace.observeTextEditors (editor) =>
      @subscriptions.add editor.onDidSave module.exports.lintOnSave
