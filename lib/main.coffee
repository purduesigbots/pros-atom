{CompositeDisposable} = require 'atom'
{NewProjectView} = require './views/new-project/new-project-view'
{RegisterProjectView} = require './views/register-project/register-project-view'
{UpgradeProjectView} = require './views/upgrade-project/upgrade-project-view'
# {`TerminalView`} = require './views/terminal/terminal-view'
{Disposable} = require 'atom'
fs = require 'fs'
cli = require './cli'
terminal = require './terminal-utilities'
GA = require './ga'
{provideBuilder} = require './make'
lint = require './lint'
config = require './config'
universalConfig = require './universal-config'
autocomplete = require './autocomplete/autocomplete-clang'
buttons = require './buttons'
StatusBar = require './views/statusbar'

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
      # Generate a new client ID if needed
      # atom.config.get 'pros.googleAnalytics.enabled' and\
      if !!atom.config.get 'pros.googleAnalytics.cid'
        atom.config.set 'pros.googleAnalytics.cid', GA.generateUUID()
      # Begin client session
      if atom.config.get 'pros.googleAnalytics.enabled' and \
         atom.config.get('core.telemetryConsent') is 'limited'
        GA.sendData()
      # Watch config to make sure we start or end sessions as needed
      atom.config.onDidChange 'pros.googleAnalytics.enabled', ->
        if atom.config.get 'pros.googleAnalytics.enabled' and \
           atom.config.get('core.telemetryConsent') is 'limited'
          if !!atom.config.get 'pros.googleAnalytics.cid'
            atom.config.set 'pros.googleAnalytics.cid', GA.generateUUID()
          GA.sendData()
        else
          GA.sendData sessionControl = 'end'

      atom.config.onDidChange 'core.telemetryConsent', ->
        if atom.config.get('core.telemetryConsent') is 'no'
          GA.sendData sessionControl = 'end'

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
      atom.commands.add 'atom-workspace',
        'PROS:Toggle-PROS': => @togglePROS()

      @subscriptions.add atom.workspace.addOpener (uri) ->
        if uri is 'pros://welcome'
          createWelcomeView uri: 'pros://welcome'
      if atom.config.get 'pros.welcome.enabled'
        @showWelcome()

      cli.execute(((c, o) -> console.log o if o),
        cli.baseCommand().concat ['conduct', 'first-run', '--no-force', '--use-defaults'])
      @PROSstatus = true

  deactivate: ->
    # End client session
    if atom.config.get 'pros.googleAnalytics.enabled' and \
       atom.config.get('core.telemetryConsent') is 'limited'
      GA.sendData sessionControl = 'end'

  togglePROS: =>
    if @PROSstatus or not @PROSstatus?
      @toolBar.removeItems()
      lint.deactivate()
      autocomplete.deactivate()
      @PROSstatus = false
    else
      buttons.addButtons @toolBar
      lint.activate()
      autocomplete.activate()
      @PROSstatus = true

  consumeLinter: lint.consumeLinter
  consumeRunInTerminal: (service) ->
    terminal.consumeRunInTerminal service

  uploadProject: ->
    if atom.project.getPaths().length > 0
      cli.uploadInTerminal '-f "' + \
        (atom.project.relativizePath(atom.workspace.getActiveTextEditor()?.getPath())[0] or \
          atom.project.getPaths()[0]) + '"'

  newProject: ->
    @newProjectPanel.toggle()

  registerProject: ->
    @registerProjectPanel.toggle()

  upgradeProject: ->
    @upgradeProjectPanel.toggle()

  toggleTerminal: -> cli.serialInTerminal()

  consumeToolbar: (getToolBar) =>
    @toolBar = getToolBar('pros')

    buttons.addButtons @toolBar

    @toolBar.onDidDestroy => @toolBar = null

  autocompleteProvider: ->
    autocomplete.provide()

  consumeStatusBar: (statusbar) ->
    @statusBarTile = new StatusBar(statusbar)

  config: universalConfig.filterConfig config.config, 'atom'
