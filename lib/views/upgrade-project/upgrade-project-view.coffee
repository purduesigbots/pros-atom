{BaseView, View} = require '../base-view'
{TextEditorView} = require 'atom-space-pen-views'
cli = require '../../cli'

module.exports =
  UpgradeProjectView: class NewProjectView extends BaseView
    constructor: ->
      super(__dirname)

      @directoryDropdown = @element.querySelector '#pros-directory-selector select'
      @templateDropdown = @element.querySelector '#pros-template-selector select'
      @upgradeBtn = @element.querySelector '#pros-upgrade-project-view-upgrade'
      @element.querySelector('#pros-upgrade-project-view-cancel').onclick = =>
        @cancel()
      @upgradeBtn.onclick = => @upgrade()

      atom.keymaps.add 'upgrade-project-view-keymap',
        '.pros-upgrade-project-view':
          'escape': 'pros-upgrade-project-view:cancel'
      atom.commands.add @element, 'pros-upgrade-project-view:cancel': => @cancel()

    createOption: (value, innerHTML) ->
      option = document.createElement('option')
      option.value = value
      option.innerHTML = innerHTML
      option

    show: ->
      super
      @directoryDropdown.appendChild(@createOption path, path) for path in atom.project.getPaths()
      @templateDropdown.appendChild @createOption({
        'depot': 'auto',
        'version': 'latest' }),
        'Automatically select latest'
      @templateDropdown.appendChild @createOption null, 'Loading...'
      cli.getTemplates ((code, result) =>
        console.log result
        @templateDropdown.removeChild @templateDropdown.lastChild
        result.forEach (e) =>
          op = document.createElement('option')
          op.value = e
          op.innerHTML = e.version + ' from ' + e.depot
          @templateDropdown.appendChild(op)
        ), '--offline-only --kernels'

    cancel: ->
      @directoryDropdown.removeChild @directoryDropdown.firstChild while @directoryDropdown.firstChild
      @templateDropdown.removeChild @templateDropdown.firstChild while @templateDropdown.firstChild
      @hide()

    upgrade: ->
      directory = @directoryDropdown.options[@directoryDropdown.selectedIndex].value
      kernel = @templateDropdown.options[@templateDropdown.selectedIndex].value.version
      depot = @templateDropdown.options[@templateDropdown.selectedIndex].value.depot
      cli.upgradeExecute(
        ((code, output) =>
          if code is 0
            atom.notifications.addSuccess 'Upgraded a project', {
              detail: output
              dismissable: true
            }
          else
            atom.notifications.addError 'Failed to upgrade project', {
              detail: output
              dismissable: true
            }
          console.log output
          ),
        '"' + directory + '"', kernel, depot)
      # cli.createNewInTerminal('"' + directory + '"', kernel, depot)
      @cancel()
