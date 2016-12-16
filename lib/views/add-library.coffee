{CompositeDisposable, Disposable} = require 'atom'
{$, View, TextEditorView} = require 'atom-space-pen-views'
fs = require 'fs'
path = require 'path'
cli = require '../cli'

module.exports =
  class AddLibraryModal extends View
    @content: ->
      @div class: 'pros-add-library', tabindex: -1, =>
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
            for p in atom.project.getPaths()
              if fs.existsSync path.join p, 'project.pros'
                @li p
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
          cli.projectInfo(((c, info) =>
            if Object.keys(info.libraries).some((k) -> info.libraries.hasOwnProperty k)
              for n, v of info.libraries
                @libraryList.children('.primary-line.icon-check').removeClass 'icon icon-check'
                for child in @libraryList.children()
                  value = $(child).data 'value'
                  if value?.library == n and value?.version == v.version
                    $(child).children('.primary-line').addClass 'icon icon-check'
            ), @projectPathEditor.getText())

      @addButton.click =>
        if dir = @projectPathEditor.getText()
          if template = @selected.data 'value'
            $(@element).find('.actions').addClass 'working'
            cli.addLibraryExecute(((c, o) =>
              @cancel(true) # destroy the modal
              if c is 0
                atom.notifications.addSuccess "Added #{template.library} to #{path.basename dir}", detail: o
                atom.project.addPath dir
              else
                atom.notifications.addError "Failed to add #{template.library} to #{path.basename dir}",
                  detail: o
                  dismissable: true
            ), "\"#{dir}\"", template.library, template.version, template.depot)

      if !!_path then @projectPathEditor.setText _path
      @panel.show()
      @projectPathEditor.focus()

      cli.getTemplates(((c, o) =>
        @libraryList.empty()
        for {library, version, depot} in o
          li = document.createElement 'li'
          li.className = 'two-lines library-option'
          li.setAttribute 'data-value', JSON.stringify {library, version, depot}
          li.innerHTML = "
          <div class='primary-line'>#{library}</div>
          <div class='secondary-line'><em>version</em> #{version} <em>from</em>
          #{depot}</div>"
          @libraryList.append li

        $('li.library-option').on 'click', (e) =>
          @selected?.removeClass 'selected'
          @selected?.children('.primary-line').removeClass 'icon icon-chevron-right'
          @selected = $(e.target).closest 'li.library-option'
          updateDisable()
          @selected.addClass 'selected'
          @selected.children('.primary-line').addClass 'icon icon-chevron-right'
        ), '--offline-only --libraries')

    cancel: (complete=false)->
      @panel?.hide()
      @panel?.destroy()
      @panel = null
      atom.workspace.getActivePane().activate()
      @cb?(complete)
