{NewProjectView} = require './views/new-project/new-project-view'
{RegisterProjectView} = require './views/register-project/register-project-view'
{UpgradeProjectView} = require './views/upgrade-project/upgrade-project-view'
{TerminalView} = require './views/terminal/terminal-view'
{Disposable} = require 'atom'
fs = require 'fs'
cli = require './cli'
{consumeDisplayConsole} = require './terminal-utilities'
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

      # atom.commands.add 'atom-work  space',
      #   'PROS:Toggle-PROS': => @togglePROS()
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

      cli.execute(((c, o) -> console.log o),
        cli.baseCommand().concat ['conduct', 'first-run', '--no-force', '--use-defaults'])

      @terminalViewPanel.toggle()
      @terminalViewPanel.toggle()

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

  consumeToolbar: (getToolBar) ->
    @toolBar = getToolBar('pros')

    # @toolBar.addButton {
    #   icon: 'folder-add',
    #   callback: 'PROS:New-Project',
    #   tooltip: 'Create a new PROS Project',
    #   iconset: 'fi'
    # }
    @toolBar.addButton {
      icon: 'upload',
      callback: 'PROS:Upload-Project'
      tooltip: 'Upload PROS project',
      iconset: 'fi'
    }
    # @toolBar.addButton {
    #   icon: 'check',
    #   callback: 'PROS:Register-Project',
    #   tooltip: 'Register PROS project',
    #   iconset: 'fi'
    # }
    # @toolBar.addButton {
    #   icon: 'arrow-circle-up',
    #   callback: 'PROS:Upgrade-Project',
    #   tooltip: 'Upgrade existing PROS project',
    #   iconset: 'fa'
    # }
    @toolBar.addButton {
      icon: 'eye-slash',
      callback: 'PROS:Toggle-Terminal',
      tooltip: 'Toggle PROS terminal output visibility'
      iconset: 'fa'
    }

    @toolBar.onDidDestroy => @toolBar = null

  autocompleteProvider: ->
    autocomplete.provide()

  consumeStatusBar: ->


  config: universalConfig.filterConfig config.config, 'atom'
