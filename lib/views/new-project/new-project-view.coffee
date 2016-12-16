{BaseView, View} = require '../base-view'
{TextEditorView} = require 'atom-space-pen-views'
fs = require 'fs'
path = require 'path'
cli = require '../../cli'

module.exports =
  NewProjectView: class NewProjectView extends BaseView
    constructor: ->
      super(__dirname)

      @dropdown = @element.querySelector('.pros-new-project-view select')
      @createBtn = @element.querySelector("#pros-new-project-view-create")
      @directoryBox = new TextEditorView mini: true,
        'Path to new project folder'
      @directoryBox.prependTo \
        @element.querySelector('#pros-directory-selector div')

      @element.querySelector("#pros-new-project-view-cancel").onclick = =>
        @cancel()
      @createBtn.onclick = => @create()
      @element.querySelector('#pros-directory-selector div button').onclick = =>
        @select_directory()

      atom.keymaps.add 'new-project-view-keymap',
        '.pros-new-project-view':
          'escape': 'pros-new-project-view:cancel'
      atom.commands.add @element, 'pros-new-project-view:cancel': => @cancel()

      @createBtn.disabled = true
      @directoryBox.getModel().onDidChange =>
        @createBtn.disabled = !!!@directoryBox.getModel().getText()

      @directoryBox.getModel().moveToEndOfLine()

    createOption: (value, innerHTML) ->
      option = document.createElement('option')
      option.value = value
      option.innerHTML = innerHTML
      option

    show: ->
      super
      @dropdown.appendChild @createOption JSON.stringify({
        'depot': 'auto',
        'version': 'latest' }),
        'Automatically select latest'
      @dropdown.appendChild @createOption null, 'Loading...'
      cli.getTemplates ((code, result) =>
        console.log result
        @dropdown.removeChild @dropdown.lastChild
        result.forEach (e) =>
          op = document.createElement('option')
          op.value = JSON.stringify e
          op.innerHTML = e.version + ' from ' + e.depot
          @dropdown.appendChild(op)
        ), '--offline-only --kernels'


    cancel: ->
      @dropdown.removeChild @dropdown.firstChild while @dropdown.firstChild
      @hide()

    select_directory: ->
      new_value = null
      atom.pickFolder((paths) =>
        if paths? and paths.length >= 1
          @directoryBox.getModel().setText paths.pop()
        )

    create: ->
      directory = @directoryBox.getModel().getText()
      kernel = JSON.parse(@dropdown.options[@dropdown.selectedIndex].value).version
      depot = JSON.parse(@dropdown.options[@dropdown.selectedIndex].value).depot
      cli.createNewExecute(((code, output) ->
        if code is 0
          atom.notifications.addSuccess 'Created a new project', {
            detail: output
            dismissable: true
          }
          atom.project.addPath directory
          firstPath = path.join directory, 'src', 'opcontrol.c'
          fs.exists firstPath, (exists) ->
            if exists then atom.workspace.open firstPath
        else
          atom.notifications.addError 'Failed to create project', {
            detail: output
            dismissable: true
          }
        console.log output
        ),
        '"' + directory + '"', kernel, depot)
      # cli.createNewInTerminal('"' + directory + '"', kernel, depot)
      @cancel()

      @directoryBox.getModel().setText ''
