{BaseView, View} = require '../base-view'
{TextEditorView} = require 'atom-space-pen-views'
cli = require '../../cli'

module.exports =
  RegisterProjectView: class NewProjectView extends BaseView
    constructor: ->
      super(__dirname)

      @directoryDropdown = @element.querySelector '#pros-directory-selector select'
      @templateDropdown = @element.querySelector '#pros-template-selector select'
      @registerBtn = @element.querySelector '#pros-register-project-view-register'
      @element.querySelector('#pros-register-project-view-cancel').onclick = =>
        @cancel()
      @registerBtn.onclick = => @register()

      atom.keymaps.add 'register-project-view-keymap',
        '.pros-register-project-view':
          'escape': 'pros-register-project-view:cancel'
      atom.commands.add @element, 'pros-register-project-view:cancel': => @cancel()

    createOption: (value, innerHTML) ->
      option = document.createElement('option')
      option.value = value
      option.innerHTML = innerHTML
      option

    show: ->
      super
      @directoryDropdown.appendChild(@createOption path, path) \
        for path in atom.project.getPaths()
      @templateDropdown.appendChild @createOption 'latest', 'Automatically select latest'
      @templateDropdown.appendChild @createOption null, 'Loading...'
      cli.getTemplates ((code, result) =>
        console.log result
        @templateDropdown.removeChild @templateDropdown.lastChild
        kernels = []
        result.forEach (e) =>
          if e.version not in kernels
            kernels.push e.version
            @templateDropdown.appendChild @createOption e.version, e.version
        ), '--offline-only --kernels'

    cancel: ->
      @directoryDropdown.removeChild @directoryDropdown.firstChild \
        while @directoryDropdown.firstChild
      @templateDropdown.removeChild @templateDropdown.firstChild \
        while @templateDropdown.firstChild
      @hide()

    register: ->
      directory = @directoryDropdown.options[@directoryDropdown.selectedIndex].value
      kernel = @templateDropdown.options[@templateDropdown.selectedIndex]
      console.log directory
      console.log kernel.value
      cli.execute(
        ((code, output) ->
          if code is 0
            atom.notifications.addSuccess 'Registered a project', {
              detail: output
              dismissable: true
            }
          else
            atom.notifications.addError 'Failed to register project', {
              detail: output or 'Check the debug log'
              dismissable: true
            }
          console.log output
          console.log "Error code was #{code}"
          ),
        cli.baseCommand('conduct', 'register', '"' + directory + '"', kernel.value))
      # cli.createNewInTerminal('"' + directory + '"', kernel, depot)
      @cancel()
