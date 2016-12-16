{$, View, TextEditorView} = require 'atom-space-pen-views'
fs = require 'fs'
path = require 'path'
cli = require '../cli'

module.exports =
  class NewProjectModal extends View
    @content: ->
      @div class: 'pros-new-project', =>
        @h1 'Create a new PROS Project'
        @div class: 'directory-selector', =>
          @h4 'Choose a directory:'
          @div style: 'display: flex; flex-direction: row-reverse;', =>
            @button class: 'btn btn-default', outlet: 'openDir', =>
              @span class: 'icon icon-ellipsis'
            @subview 'projectPathEditor', new TextEditorView mini: true
        @div class: 'kernel-selector', =>
          @h4 'Choose a kernel:'
          @select class: 'input-select', outlet: 'kernelsList', =>
            @option class: 'temp', 'Loading...'
        @div class: 'actions', =>
          @div class: 'btn-group', =>
            @button outlet: 'cancelButton', class: 'btn', 'Cancel'
            @button outlet: 'createButton', class: 'btn btn-primary icon icon-rocket', 'Create'
          @span class: 'loading loading-spinner-tiny'

    initialize: ({dir}={}) ->
      atom.keymaps.add 'new-project-keymap',
        '.pros-new-project':
          'escape': 'core:cancel'
      atom.commands.add @element, 'core:cancel', => @cancel()
      @panel ?= atom.workspace.addModalPanel item: this, visible: false

      @createButton.prop 'disabled', true
      @projectPathEditor.getModel().onDidChange =>
        @createButton.prop 'disabled', !!!@projectPathEditor.getText()

      @openDir.click => atom.pickFolder (paths) =>
        if paths?[0]
          @projectPathEditor.setText paths[0]

      @createButton.click =>
        if dir = @projectPathEditor.getText()
          template = JSON.parse @kernelsList.val()
          $(@element).find('.actions').addClass 'working'
          cli.createNewExecute(((c,o) =>
            @cancel() # destroy the modal
            if c is 0
              atom.notifications.addSuccess 'Created a new project', detail: o
              atom.project.addPath dir
              firstPath = path.join dir, 'src', 'opcontrol.c'
              fs.exists firstPath, (exists) -> if exists then atom.workspace.open firstPath, pending: true
            else
              atom.notifications.addError 'Failed to create project',
                detail: o
                dismissable: true
            ), "\"#{dir}\"", template.version, template.depot)

      @cancelButton.click => @cancel()

      if dir then @projectPathEditor.setText dir
      option = document.createElement 'option'
      option.value = JSON.stringify {'depot': 'auto', 'version': 'latest'}
      option.innerHTML = 'Auto-select latest'
      @kernelsList.prepend option
      @panel.show()
      @projectPathEditor.focus()

      cli.getTemplates ((code, result) =>
        @kernelsList.children().last().remove()
        result.forEach (kernel) =>
          option = document.createElement 'option'
          option.value = JSON.stringify kernel
          option.innerHTML = "#{kernel.version} from #{kernel.depot}"
          @kernelsList.append option
        ), '--offline-only --kernels'

    cancel: =>
      @panel?.hide()
      @panel?.destroy()
      @panel = null
      atom.workspace.getActivePane().activate()
