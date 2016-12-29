{CompositeDisposable} = require 'atom'
{$, ScrollView, TextEditorView} = require 'atom-space-pen-views'
fs = require 'fs'
cli = require '../proscli'

module.exports =
  class AddDepotModal extends ScrollView
    @content: ->
      @div class: 'pros-add-depot', tabindex: -1, =>
        @h1 'Add a new PROS Depot'
        @h4 'Choose a registrar:'
        @div class: 'registrar-picker select-list', =>
          @ol class: 'list-group', outlet: 'registrarList', =>
            @li 'Loading...'
        @h4 'Name the depot:'
        @subview 'nameEditor', new TextEditorView mini: true
        @h4 'Depot location:'
        @subview 'locationEditor', new TextEditorView mini: true
        @div class: 'actions', =>
          @div class: 'btn-group', =>
            @button outlet: 'cancelButton', class: 'btn', 'Cancel'
            @button outlet: 'addButton', class: 'btn btn-primary icon icon-rocket', 'Add Library'
          @span class: 'loading loading-spinner-tiny'

    initialize: ({@cb}={}) ->
      atom.keymaps.add 'add-depot-keymap',
        '.pros-add-depot':
          'escape': 'core:cancel'
      atom.commands.add @element, 'core:cancel', => @cancel()
      @panel ?= atom.workspace.addModalPanel item: this, visible: false

      @cancelButton.click => @cancel()

      updateDisable = =>
        if !!!@nameEditor.getText()
          @addButton.prop 'disabled', true
        else if !!!@locationEditor.getText()
          @addButton.prop 'disabled', true
        else
          @addButton.prop 'disabled', false

      @nameEditor.getModel().onDidChange -> updateDisable()
      @locationEditor.getModel().onDidChange -> updateDisable()
      @panel.show()
      @nameEditor.focus()

    cancel: (complete=false) ->
      @panel?.hide()
      @panel?.destroy()
      @panel = null
      atom.workspace.getActivePane().activate()
      @cb? complete
