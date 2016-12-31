{CompositeDisposable} = require 'atom'
{$, ScrollView, TextEditorView} = require 'atom-space-pen-views'
fs = require 'fs'
cli = require '../proscli'
std = require './standard'

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
        @h4 'Options'
        @div class: 'depotOptions', outlet: 'depotOptions'
        @div class: 'actions', =>
          @div class: 'btn-group', =>
            @button outlet: 'cancelButton', class: 'btn', 'Cancel'
            @button outlet: 'addButton', tabindex: 100, class: 'btn btn-primary icon icon-rocket',
              'Add Depot'
          @span class: 'loading loading-spinner-tiny'

    depotConfig: {}
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
        else if !@selectedRegistrar
          @addButton.prop 'disabled', true
        else
          @addButton.prop 'disabled', false

      cli.execute {
        cmd: ['pros', 'conduct', 'ls-registrars', '--machine-output'],
        cb: (c, o, e) =>
          @registrarList.empty()
          if c != 0
            std.addMessage @registrarList,
            "Error getting list of registars.<br/>STDOUT:<br/>#{o}<br/><br/>ERR:</br>#{e}",
            error: true
            return
          try
            registrars = JSON.parse o
          catch error
            std.addMessage @registrarList,
            "Error parsing the list of registrars.<br/>Exception:#{error}",
            error: true
            return
          for own key, value of registrars
            @registrarList.append "<li>#{key}</li>"
          @registrarList.children().first().click()
      }

      @on 'click', '.registrar-picker li', (e) =>
        @selectedRegistrar?.removeClass 'select'
        @selectedRegistrar = $(e.target.closest 'li')
        @selectedRegistrar.addClass 'select'
        @depotConfig = {}
        std.createDepotConfig @depotOptions, @updateDepotConfig, {registrar: @selectedRegistrar.text()}

      @addButton.click =>
        console.log @depotConfig
        cli.execute {
          cmd: ['pros', 'conduct', 'add-depot',
          '--name', @nameEditor.getText(), '--registrar', @selectedRegistrar.text(),
          '--location', @locationEditor.getText(), '--no-configure', '--options', JSON.stringify @depotConfig]
          cb: (c, o, e) =>
            if c != 0
              atom.notifications.addError 'Error adding new PROS depot',
                detail: "OUT:\n#{o}\n\nERR:\n#{e}",
                dismissable: true
            else
              atom.notifications.addSuccess "Added #{@nameEditor.getText()} as a PROS depot"
              @cancel true
        }
      @nameEditor.getModel().onDidChange -> updateDisable()
      @locationEditor.getModel().onDidChange -> updateDisable()
      updateDisable()
      @panel.show()
      @nameEditor.focus()

    updateDepotConfig: (depot, key, value) =>
      @depotConfig[key] = value

    cancel: (complete=false) ->
      @panel?.hide()
      @panel?.destroy()
      @panel = null
      atom.workspace.getActivePane().activate()
      @cb? {complete, name: @nameEditor.getText()}
