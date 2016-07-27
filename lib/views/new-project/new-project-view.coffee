{BaseView, View} = require '../base-view'
{TextEditorView} = require 'atom-space-pen-views'
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
      @dropdown.appendChild @createOption {
        'depot': 'auto',
        'version': 'latest' },
        'Automatically select latest'
      @dropdown.appendChild @createOption null, 'Loading...'
      cli.getTemplates ((result) =>
        console.log result
        @dropdown.removeChild @dropdown.lastChild
        result.forEach (e) =>
          op = document.createElement('option')
          op.value = e
          op.innerHTML = e.version + ' from ' + e.depot
          @dropdown.appendChild(op)
        ), '--offline-only'


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
      kernel = @dropdown.options[@dropdown.selectedIndex].version
      depot = @dropdown.options[@dropdown.selectedIndex].depot
      cli.createNewInTerminal('"' + directory + '"', kernel, depot)
      @cancel()
      atom.open({
        pathsToOpen: [@directoryBox.getModel().getText()],
        newWindow: true,
        devMode: atom.inDevMode(),
        safeMode: atom.inSafeMode()
      })
      @directoryBox.getModel().setText ''
