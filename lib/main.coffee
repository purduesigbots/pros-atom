{CompositeDisposable} = require 'atom'
{NewProjectView} = require './views/new-project/new-project-view'
{RegisterProjectView} = require './views/register-project/register-project-view'
{UpgradeProjectView} = require './views/upgrade-project/upgrade-project-view'
# {`TerminalView`} = require './views/terminal/terminal-view'
{Disposable} = require 'atom'
fs = require 'fs'
cli = require './cli'
terminal = require './terminal-utilities'
{provideBuilder} = require './make'
lint = require './lint'
config = require './config'
universalConfig = require './universal-config'
autocomplete = require './autocomplete/autocomplete-clang'

WelcomeView = null

createWelcomeView = (state) ->
  WelcomeView = require './views/welcome/welcome-view'
  new WelcomeView(state)

module.exports =
  provideBuilder: provideBuilder

  showWelcome: ->
    atom.workspace.open 'pros://welcome'

  activate: ->
    @subscriptions = new CompositeDisposable
    require('atom-package-deps').install('pros').then () =>
      if config.settings('').override_beautify_provider
        atom.config.set('atom-beautify.c.default_beautifier', 'clang-format')
      lint.activate()
      autocomplete.activate()
      @newProjectViewProvider = NewProjectView.register
      @newProjectPanel = new NewProjectView

      @registerProjectViewProvider = RegisterProjectView.register
      @registerProjectPanel = new RegisterProjectView

      @upgradeProjectViewProvider = UpgradeProjectView.register
      @upgradeProjectPanel = new UpgradeProjectView

      @subscriptions.add atom.deserializers.add
        name: 'ProsWelcomeView'
        deserialize: (state) -> createWelcomeView state

      atom.commands.add 'atom-workspace',
        'PROS:New-Project': => @newProject()
      atom.commands.add 'atom-workspace',
        'PROS:Upgrade-Project': => @upgradeProject()
      atom.commands.add 'atom-workspace',
        'PROS:Register-Project': => @registerProject()
      atom.commands.add 'atom-workspace',
        'PROS:Upload-Project': => @uploadProject()
      atom.commands.add 'atom-workspace',
        'PROS:Toggle-Terminal': => @toggleTerminal()
      atom.commands.add 'atom-workspace',
        'PROS:Show-Welcome': => @showWelcome()
      # name subject to change, this just seems the most descriptive
      atom.commands.add 'atom-workspace',
        'PROS:Open-Cortex': => @openCortex()

      @subscriptions.add atom.workspace.addOpener (uri) ->
        if uri is 'pros://welcome'
          createWelcomeView uri: 'pros://welcome'
      @showWelcome()

      cli.execute(((c, o) -> console.log o),
        cli.baseCommand().concat ['conduct', 'first-run', '--no-force', '--use-defaults'])

  consumeLinter: lint.consumeLinter
  consumeRunInTerminal: (service) ->
    terminal.consumeRunInTerminal service

  uploadProject: ->
    if atom.project.getPaths().length > 0
      cli.uploadInTerminal '-f "' + \
        (atom.project.relativizePath(atom.workspace.getActiveTextEditor().getPath())[0] or \
          atom.project.getPaths()[0]) + '"'

  newProject: ->
    @newProjectPanel.toggle()

  registerProject: ->
    @registerProjectPanel.toggle()

  upgradeProject: ->
    @upgradeProjectPanel.toggle()

  toggleTerminal: -> cli.serialInTerminal()

  consumeToolbar: (getToolBar) ->
    @toolBar = getToolBar('pros')

    @toolBar.addButton {
      icon: 'upload',
      callback: 'PROS:Upload-Project'
      tooltip: 'Upload PROS project',
      iconset: 'fi'
    }
    @toolBar.addButton {
      icon: 'circuit-board',
      callback: 'PROS:Toggle-Terminal',
      tooltip: 'Open cortex serial output'
    }

    @toolBar.onDidDestroy => @toolBar = null

  autocompleteProvider: ->
    autocomplete.provide()

  consumeStatusBar: (statusbar) ->
    terminal.statusBar = statusbar

  config: universalConfig.filterConfig config.config, 'atom'
