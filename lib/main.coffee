{CompositeDisposable} = require 'atom'
{RegisterProjectView} = require './views/register-project/register-project-view'
# {`TerminalView`} = require './views/terminal/terminal-view'
{Disposable} = require 'atom'
fs = require 'fs'
path = require 'path'
cli = require './cli'
terminal = require './terminal-utilities'
GA = require './ga'
{provideBuilder} = require './make'
lint = require './lint'
config = require './config'
universalConfig = require './universal-config'
autocomplete = require './autocomplete/autocomplete-clang'
buttons = require './buttons'
Status = require './views/statusbar'
utils = require './utils'

WelcomeView = null
ConductorView = null
AddLibraryModal = null

welcomeUri = 'pros://welcome'
conductorUri = 'pros://conductor'
conductorRegex = /conductor\/(.+)/i
addLibraryUri = 'pros://addlib'
addLibraryRegex = /addlib\/(.+)/i

module.exports =
  provideBuilder: provideBuilder

  activate: ->
    @subscriptions = new CompositeDisposable
    require('atom-package-deps').install('pros').then () =>
      # Generate a new client ID if needed
      # atom.config.get 'pros.googleAnalytics.enabled' and\
      # Begin client session
      GA.startSession()
      # Watch config to make sure we start or end sessions as needed
      atom.config.onDidChange 'pros.googleAnalytics.enabled', ->
        if atom.config.get('pros.googleAnalytics.enabled') and \
           atom.config.get('core.telemetryConsent') is 'limited'
          GA.startSession()
        else
          atom.config.set 'pros.googleAnalytics.cid', ''
          GA.sendData sessionControl = 'end'

      atom.config.onDidChange 'core.telemetryConsent', ->
        if atom.config.get('core.telemetryConsent') is 'no'
          GA.sendData sessionControl = 'end'

      if config.settings('').override_beautify_provider
        atom.config.set('atom-beautify.c.default_beautifier', 'clang-format')
      lint.activate()
      autocomplete.activate()

      @registerProjectViewProvider = RegisterProjectView.register
      @registerProjectPanel = new RegisterProjectView

      @subscriptions.add atom.deserializers.add
        name: 'ProsWelcomeView'
        deserialize: (state) -> createWelcomeView state

      atom.commands.add 'atom-workspace', 'PROS:New-Project': -> new (require './views/new-project')
      atom.commands.add 'atom-workspace', 'PROS:Upgrade-Project': ->
        currentProject = atom.project.relativizePath atom.workspace.getActiveTextEditor()?.getPath()
        if currentProject[0] then new ( require './views/upgrade-project') dir: currentProject[0]
        else new (require './views/upgrade-project')
      atom.commands.add 'atom-workspace', 'PROS:Register-Project': => @registerProject()
      atom.commands.add 'atom-workspace', 'PROS:Upload-Project': => @uploadProject()
      atom.commands.add 'atom-workspace', 'PROS:Toggle-Terminal': => @toggleTerminal()
      atom.commands.add 'atom-workspace', 'PROS:Show-Welcome': -> atom.workspace.open welcomeUri
      atom.commands.add 'atom-workspace', 'PROS:Toggle-PROS': => @togglePROS()
      atom.commands.add 'atom-workspace', 'PROS:Open-Conductor': ->
        currentProject = atom.project.relativizePath atom.workspace.getActiveTextEditor()?.getPath()
        if currentProject[0]
          atom.workspace.open "#{conductorUri}/#{currentProject[0]}"
        else
          atom.workspace.open conductorUri
      atom.commands.add 'atom-workspace',
        'PROS:Add-Library': ->
          new (require './views/add-library') path: atom.project.getPaths()?[0]

      @subscriptions.add atom.workspace.addOpener (uri) ->
        if uri is welcomeUri
          console.log WelcomeView ?= (require './react/conductor')
          return WelcomeView

      @subscriptions.add atom.workspace.addOpener (uri) ->
        if uri.startsWith conductorUri
          ConductorView ?= new (require('./views/conductor')) {conductorUri}
          if match = conductorRegex.exec uri
            ConductorView.updateAvailableProjects()
            ConductorView.updateSelectedPath match[1]
          ConductorView

      if atom.config.get 'pros.welcome.enabled'
        atom.workspace.open welcomeUri

      cli.execute(((c, o) -> console.log o if o),
        cli.baseCommand().concat ['conduct', 'first-run', '--no-force', '--use-defaults'])
      @PROSstatus = true

      grammarSubscription = atom.grammars.onDidAddGrammar (grammar) ->
        if grammar.scopeName is 'source.json'
          grammarSubscription.dispose()
          grammar.fileTypes.push 'pros'
          process.nextTick ->
            for e in atom.workspace.getTextEditors()
              if path.extname(e.getPath()) == '.pros'
                e.setGrammar grammar

  deactivate: ->
    @statusBarTile?.destroy()
    @statusBarTile = null
    # End client session
    if atom.config.get('pros.googleAnalytics.enabled') and \
       atom.config.get('core.telemetryConsent') is 'limited'
      GA.sendData sessionControl = 'end'

  togglePROS: =>
    if @PROSstatus or not @PROSstatus?
      @toolBar.removeItems()
      lint.deactivate()
      autocomplete.deactivate()
      # build.deactivate()
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

  registerProject: -> @registerProjectPanel.toggle()

  toggleTerminal: -> cli.serialInTerminal()

  consumeToolbar: (getToolBar) =>
    @toolBar = getToolBar('pros')
    buttons.addButtons @toolBar
    @toolBar.onDidDestroy => @toolBar = null

  autocompleteProvider: -> autocomplete.provide()

  consumeStatusBar: (statusbar) ->
    Status.attach(statusbar)

  deserializeConductorView: (data) -> ConductorView ?= new (require('./views/conductor')) data

  config: universalConfig.filterConfig config.config, 'atom'
