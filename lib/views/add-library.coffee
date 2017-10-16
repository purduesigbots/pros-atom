{CompositeDisposable, Disposable} = require 'atom'
{$, View, TextEditorView} = require 'atom-space-pen-views'
fs = require 'fs'
path = require 'path'
utils = require '../utils'
proscli = require '../proscli'
{prosConduct} = proscli
std = require './standard'

module.exports =
  class AddLibraryModal extends View
    @content: ->
      @div class: 'pros-modal pros-add-library', tabindex: -1, =>
        @h1 'Add Library to PROS Project'
        @h4 'Choose a project:'
        @div class: 'select-list', id: 'projectPathPicker', outlet: 'projectPathPicker', =>
          @div style: 'display: flex; flex-direction: row-reverse;', =>
            @button class: 'btn btn-default', outlet: 'openDir', =>
              @span class: 'icon icon-ellipsis'
            @button class: 'btn btn-default', outlet: 'toggleListButton', =>
              @span class: 'icon icon-three-bars'
            @subview 'projectPathEditor', new TextEditorView mini: true
          @ol class: 'list-group', =>
            (@li p) for p in utils.findOpenPROSProjectsSync()
        @h4 'Choose a library:'
        @div class: 'library-picker select-list', =>
          @ol class: 'list-group', outlet: 'libraryList', =>
            @li 'Loading...'
        @div class: 'actions', =>
          @div class: 'btn-group', =>
            @button outlet: 'cancelButton', class: 'btn', 'Cancel'
            @button outlet: 'addButton', class: 'btn btn-primary icon icon-rocket', 'Add Library'
          @span class: 'loading loading-spinner-tiny'


    initialize: ({_path, @cb}={}) ->
      @subscriptions ?= new CompositeDisposable
      atom.keymaps.add 'add-library-keymap',
        '.pros-add-library':
          'escape': 'core:cancel'
      atom.commands.add @element, 'core:cancel', => @cancel()
      @panel ?= atom.workspace.addModalPanel item: this, visible: false

      @cancelButton.click => @cancel()

      @openDir.click => atom.pickFolder (paths) =>
        if paths?[0]
          @projectPathEditor.setText paths[0]
          $('#projectPathPicker ol').removeClass 'enabled'

      @toggleListButton.click -> $('#projectPathPicker ol').toggleClass 'enabled'

      $('#projectPathPicker ol li').on 'click', (e) =>
        @projectPathEditor.setText e.target.innerText
        $('#projectPathPicker ol').removeClass 'enabled'

      updateDisable = =>
        if !!!@projectPathEditor.getText()
          @addButton.prop 'disabled', true
        else if !fs.existsSync path.join @projectPathEditor.getText(), 'project.pros'
          @addButton.prop 'disabled', true
        else if not @selected
          @addButton.prop 'disabled', true
        else
          @addButton.prop 'disabled', false

      @projectPathEditor.getModel().onDidChange =>
        updateDisable()
        if fs.existsSync path.join @projectPathEditor.getText(), 'project.pros'
          proscli.execute {
            cmd: prosConduct('info-project', @projectPathEditor.getText()),
            cb: (c, o, e) =>
              if c != 0 then return
              info = {}
              try
                info = JSON.parse o
              catch error
                console.log error
                return
              if Object.keys(info.libraries).some((k) -> info.libraries.hasOwnProperty k)
                for n, v of info.libraries
                  @libraryList.children('.primary-line.icon-check').removeClass 'icon icon-check'
                  for child in @libraryList.children()
                    value = $(child).data 'value'
                    if value?.library == n and value?.version == v.version
                      $(child).children('.primary-line').addClass 'icon icon-check'
          }

      @addButton.click =>
        dir = @projectPathEditor.getText()
        template = @selected.data 'value'
        $(@element).find('.actions').addClass 'working'
        proscli.execute {
          cmd: prosConduct 'new-lib', dir, template.library, template.version, template.depot
          cb: (c, o, e) =>
            @cancel true
            if c == 0
              atom.notifications.addSuccess "Added #{template.library} to #{path.basename dir}", detail: o
              atom.project.addPath dir
            else
              atom.notifications.addError "Failed to add #{template.library} to #{path.basename dir}",
                detail: o
                dismissable: true
        }

      if !!_path then @projectPathEditor.setText _path
      @panel.show()
      @projectPathEditor.focus()

      @on 'click', '.library-picker li', (e) =>
        @selected?.removeClass 'selected'
        @selected?.children('.primary-line').removeClass 'icon icon-chevron-right'
        @selected = $(e.target).closest 'li.library-option'
        updateDisable()
        @selected.addClass 'selected'
        @selected.children('.primary-line').addClass 'icon icon-chevron-right'

      proscli.execute {
        cmd: prosConduct 'ls-template', '--libraries', '--offline-only', '--machine-output'
        cb: (c, o, e) =>
          @libraryList.empty()
          if c != 0
            @subscriptions.add std.addMessage @libraryList,
              "Error obtaining the list of libraries downloaded.<br/>STDOUT:<br/>#{o}<br/><br/>ERR:<br/>#{e}",
              error: true
            return
          try
            listing = JSON.parse o
          catch error
            @subscriptions.add std.addMessage @libraryList,
              "Error parsing the list of downloaded libraries (#{o}).<br/>#{error}", error: true
            return
          if listing.length == 0
            @subscriptions.add std.addMessage @libraryList,
              "You don't have any downloaded libraries.<br/>
              Visit <a>Conductor</a> to download some."
            @libraryList.find('a').on 'click', =>
              @cancel()
              atom.workspace.open 'pros://conductor'
            return
          for {library, version, depot} in listing
            li = document.createElement 'li'
            li.className = 'two-lines library-option'
            li.setAttribute 'data-value', JSON.stringify {library, version, depot}
            li.innerHTML = "
            <div class='primary-line'>#{library}</div>
            <div class='secondary-line'><em>version</em> #{version} <em>from</em>
            #{depot}</div>"
            @libraryList.append li
      }

    cancel: (complete=false)->
      @panel?.hide()
      @panel?.destroy()
      @panel = null
      atom.workspace.getActivePane().activate()
      @cb?(complete)
