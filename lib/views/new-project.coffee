{CompositeDisposable} = require 'atom'
{$, View, TextEditorView} = require 'atom-space-pen-views'
fs = require 'fs'
path = require 'path'
{prosConduct} = cli = require '../proscli'

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
        @div class: 'kernel-selector', outlet: 'kernelSelector', =>
          @h4 'Choose a kernel:'
          @select class: 'input-select', outlet: 'kernelsList', =>
            @option class: 'temp', 'Loading...'
        @div class: 'actions', =>
          @div class: 'btn-group', =>
            @button outlet: 'cancelButton', class: 'btn', 'Cancel'
            @button outlet: 'createButton', class: 'btn btn-primary icon icon-rocket', 'Create'
          @span class: 'loading loading-spinner-tiny'

    initialize: ({dir, @cb}={}) ->
      @subscriptions = new CompositeDisposable
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
          cli.execute {
            cmd: prosConduct 'new', dir, template.version, template.depot
            cb: (c, o, e) =>
              @cancel true # destroy the modal
              if c is 0
                atom.notifications.addSuccess 'Created a new project', detail: o
                atom.project.addPath dir
                firstPath = path.join dir, 'src', 'opcontrol.c'
                fs.exists firstPath, (exists) -> if exists then atom.workspace.open firstPath, pending: true
              else
                atom.notifications.addError 'Failed to create project',
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
            @subscriptions.add std.addMessage @kernelSelector,
              "Error parsing the list of downloaded kernels (#{o}).<br/>#{error}", error: true, nohide: true
            return
          if listing.length == 0
            @subscriptions.add std.addMessage @kernelSelector,
              "You don't have any downloaded kernels.<br/>
              Visit <a>Conductor</a> to download some.", nohide: true
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
