
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
      # TODO: if it isn't already set...
      atom.config.set 'pros.google-analytics.cid', GA.generateUUID()
      GA.sendData() # begin client session
      # TODO: observe config for changes to pros.google-analytics.enabled, and
      #       start or end a session based on that.
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

  deactivate: ->
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
    # TODO: config stuff
    atom.config.set 'pros.google-analytics.enabled', \
    not atom.config.get 'pros.google-analytics.enabled'

  consumeToolbar: (getToolBar) =>
    @toolBar = getToolBar('pros')

    addButtons @toolBar

    @toolBar.onDidDestroy => @toolBar = null

  autocompleteProvider: ->
    autocomplete.provide()

  consumeStatusBar: ->


  config: universalConfig.filterConfig config.config, 'atom'
    # 'google-analytics':
    #   'enabled':
    #     title: 'Google Analytics'
    #     description: \
    #     'If set to \'true,\' you help us to understand and better cater to our'+\
    #     'user-base by sending us information about the size, relative geograph'+\
    #     'ic area, and general activities of the people using PROS.'
    #     type: 'boolean'
    #     default: true
    #   'cid':
    #     title: 'Google Analytics client ID'
    #     description: \
    #     'Used when making requests to the GA API.
    #     Please do not change this value unless you have \'enabled\' set to \'false\''
    #     type: 'string'
    #     default: ''
