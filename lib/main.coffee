{NewProjectView} = require './views/new-project/new-project-view'
{Disposable} = require 'atom'
fs = require 'fs'
{consumeRunInTerminal} = require './terminal-utilities'
{provideBuilder} = require './make'
lint = require './lint'
config = require './config'

module.exports =
  consumeRunInTerminal: consumeRunInTerminal
  provideBuilder: provideBuilder

  activate: ->
    lint.activate()
    require('atom-package-deps').install('purdueros').then () =>
      @newProjectViewProvider = NewProjectView.register
      @newProjectPanel = new NewProjectView

      atom.commands.add 'atom-workspace',
        'PROS:New-Project': => @newProject()


  consumeLinter: lint.consumeLinter

  newProject: ->
    @newProjectPanel.toggle()

  consumeToolbar: (getToolBar) ->
    @toolBar = getToolBar('purdueros')

    @toolBar.addButton {
      icon: 'folder-add',
      callback: 'PROS:New-Project',
      tooltip: 'Create a new PROS Project',
      iconset: 'fi'
    }

    @toolBar.onDidDestroy => @toolBar = null

  config: config.config
