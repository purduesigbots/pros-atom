{CompositeDisposable} = require 'atom'
{$, View, TextEditorView} = require 'atom-space-pen-views'
fs = require 'fs'
path = require 'path'
{prosConduct} = cli = require '../proscli'
std = require './standard'
utils = require '../utils'

module.exports =
  class UpgradeProjectModal extends View
    @content: ->
      @div class: 'pros-modal pros-upgrade-project', =>
        @h1 'Upgrade a PROS Project'
        @div class: 'directory-selector', =>
          @h4 'Choose a directory:'
          @div class: 'select-list', id: 'projectPathPicker', outlet: 'projectPathPicker', =>
            @div style: 'display: flex; flex-direction: row-reverse;', =>
              @button class: 'btn btn-default', outlet: 'openDir', =>
                @span class: 'icon icon-ellipsis'
              @button class: 'btn btn-default', outlet: 'toggleListButton', =>
                @span class: 'icon icon-three-bars'
              @subview 'projectPathEditor', new TextEditorView mini: true
            @ol class: 'list-group', =>
              (@li p) for p in atom.project.getPaths()
        @div class: 'kernel-selector', outlet: 'kernelSelector', =>
          @h4 'Choose a kernel:'
          @select class: 'input-select', outlet: 'kernelsList', =>
            @option class: 'temp', 'Loading...'
        @div class: 'actions', =>
          @div class: 'btn-group', =>
            @button outlet: 'cancelButton', class: 'btn', 'Cancel'
            @button outlet: 'registerButton', class: 'btn btn-primary icon icon-rocket', 'Register'
          @span class: 'loading loading-spinner-tiny'

    initialize: ({dir, @cb}={}) ->
      @subscriptions = new CompositeDisposable
      atom.keymaps.add 'new-project-keymap',
        '.pros-new-project':
          'escape': 'core:cancel'
      atom.commands.add @element, 'core:cancel', => @cancel()
      @panel ?= atom.workspace.addModalPanel item: this, visible: false

      @registerButton.prop 'disabled', true
      @projectPathEditor.getModel().onDidChange =>
        @registerButton.prop 'disabled', !!!@projectPathEditor.getText()

      @toggleListButton.click -> $('#projectPathPicker ol').toggleClass 'enabled'

      @openDir.click => atom.pickFolder (paths) =>
        if paths?[0]
          @projectPathEditor.setText paths[0]

      @registerButton.click =>
        if dir = @projectPathEditor.getText()
          template = JSON.parse @kernelsList.val()
          $(@element).find('.actions').addClass 'working'
          cli.execute {
            cmd: prosConduct 'register', dir, template.version
            cb: (c, o, e) =>
              @cancel true # destroy the modal
              if c is 0
                atom.notifications.addSuccess "Registered a project", detail: o
                atom.project.addPath dir
              else
                atom.notifications.addError 'Failed to upgrade project',
                  detail: "OUT:\n#{o}\n\nERR:#{e}"
                  dismissable: true
          }

      @cancelButton.click => @cancel()

      if dir then @projectPathEditor.setText dir
      option = document.createElement 'option'
      option.value = JSON.stringify {'depot': 'auto', 'version': 'latest'}
      option.innerHTML = 'Auto-select latest'
      @kernelsList.prepend option
      @panel.show()
      @projectPathEditor.focus()

      cli.execute {
        cmd: prosConduct 'ls-template', '--kernels', '--offline-only', '--machine-output'
        cb: (c, o, e) =>
          if c != 0
            @subscriptions.add std.addMessage @kernelSelector,
              "Error obtaining the list of kernels downloaded.<br/>STDOUT:<br/>#{o}<br/><br/>ERR:<br/>#{e}",
              error: true, nohide: true
            return
          try
            listing = JSON.parse o
          catch error
            @subscriptions.add std.addMessage @kernelsList,
              "Error parsing the list of downloaded kernels (#{o}).<br/>#{error}", error: true
            return
          if listing.length == 0
            @subscriptions.add std.addMessage @kernelsList,
              "You don't have any downloaded kernels.<br/>
              Visit <a>Conductor</a> to download some."
            @kernelsList.find('a').on 'click', =>
              @cancel()
              atom.workspace.open 'pros://conductor'
            return
          @kernelsList.children().last().remove()
          listing.forEach (kernel) =>
            option = document.createElement 'option'
            option.value = JSON.stringify kernel
            option.innerHTML = "#{kernel.version} from #{kernel.depot}"
            @kernelsList.append option
        }

    cancel: (cancel=false)=>
      @panel?.hide()
      @panel?.destroy()
      @panel = null
      atom.workspace.getActivePane().activate()
      @cb? cancel, @projectPathEditor.getText()
