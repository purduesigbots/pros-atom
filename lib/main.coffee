
{NewProjectView} = require './views/new-project/new-project-view'
{RegisterProjectView} = require './views/register-project/register-project-view'
{UpgradeProjectView} = require './views/upgrade-project/upgrade-project-view'
{TerminalView} = require './views/terminal/terminal-view'
{Disposable} = require 'atom'
fs = require 'fs'
cli = require './cli'
{consumeDisplayConsole} = require './terminal-utilities'
GA = require './ga'
{addButtons} = require './pros-buttons'
{provideBuilder} = require './make'
lint = require './lint'
config = require './config'
universalConfig = require './universal-config'
autocomplete = require './autocomplete/autocomplete-clang'

module.exports =
  provideBuilder: provideBuilder

  activate: ->
    require('atom-package-deps').install('pros').then () =>
      if config.settings('').override_beautify_provider
        atom.config.set('atom-beautify.c.default_beautifier', 'clang-format')
      # Generate a new client ID if needed
      # atom.config.get 'pros.googleAnalytics.enabled' and\
      if !!atom.config.get 'pros.googleAnalytics.cid'
        atom.config.set 'pros.googleAnalytics.cid', GA.generateUUID()
      # Begin client session
      if atom.config.get 'pros.googleAnalytics.enabled'
        GA.sendData()
      # Watch config to make sure we start or end sessions as needed
      atom.config.onDidChange 'pros.googleAnalytics.enabled', ->
        if atom.config.get 'pros.googleAnalytics.enabled'
          if !!atom.config.get 'pros.googleAnalytics.cid'
            atom.config.set 'pros.googleAnalytics.cid', GA.generateUUID()
          GA.sendData()
        else
          GA.sendData sessionControl = 'end'
      lint.activate()
      autocomplete.activate()
      @newProjectViewProvider = NewProjectView.register
      @newProjectPanel = new NewProjectView

      @registerProjectViewProvider = RegisterProjectView.register
      @registerProjectPanel = new RegisterProjectView

      @upgradeProjectViewProvider = UpgradeProjectView.register
      @upgradeProjectPanel = new UpgradeProjectView

      @terminalViewProvider = TerminalView.register
      @terminalViewPanel = new TerminalView

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
        'PROS:Toggle-PROS': => @togglePROS()
      atom.commands.add 'atom-workspace',
        'PROS:Toggle-GA': => @toggleGA()

      cli.execute(((c, o) -> console.log o),
        cli.baseCommand().concat ['conduct', 'first-run', '--no-force', '--use-defaults'])

      @terminalViewPanel.toggle()
      @terminalViewPanel.toggle()
      console.log universalConfig.filterConfig config.config, 'atom'

  deactivate: ->
    # End client session
    if atom.config.get 'pros.googleAnalytics.enabled'
      GA.sendData sessionControl = 'end'

  consumeLinter: lint.consumeLinter

  uploadProject: ->
    if atom.project.getPaths().length > 0
      cli.uploadInTerminal '-f ' + atom.project.getPaths()[0]

  newProject: ->
    @newProjectPanel.toggle()

  registerProject: ->
    @registerProjectPanel.toggle()

  upgradeProject: ->
    @upgradeProjectPanel.toggle()

  toggleTerminal: ->
    @terminalViewPanel.toggle()

  togglePROS: =>
    if @PROSstatus or not @PROSstatus?
      @toolBar.removeItems()
      lint.deactivate()
      autocomplete.deactivate()
      GA.sendData sessionControl = 'end'
      @PROSstatus = false
    else
      addButtons @toolBar
      lint.activate()
      autocomplete.activate()
      GA.sendData()
      @PROSstatus = true

  toggleGA: ->
    atom.config.set 'pros.googleAnalytics.enabled', \
    not atom.config.get 'pros.googleAnalytics.enabled'

  consumeToolbar: (getToolBar) =>
    @toolBar = getToolBar('pros')

    addButtons @toolBar

    @toolBar.onDidDestroy => @toolBar = null

  autocompleteProvider: ->
    autocomplete.provide()

  consumeStatusBar: ->


  config: universalConfig.filterConfig config.config, 'atom'
