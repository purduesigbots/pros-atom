{$, TextEditorView} = require 'atom-space-pen-views'
cli = require '../proscli'

hideChildren = (element) ->
  element.children().not(element.children ':header').not(element.children '.header').css 'display', 'none'

showChildren = (element) ->
  element.children().not(element.children ':header').not(element.children '.header').css 'display', ''

module.exports =
  errorPresenter: (settings) ->
    @div Object.assign(settings, class: 'error-presenter'), =>
      @ul class: 'background-message error-messages', => @raw 'Error!'
      @div()

  applyLoading: (element) ->
    if not element.hasClass 'loading'
      element.addClass 'loading'
      hideChildren element
      loading = element.append "<span class='loading loading-spinner-medium'></span>"
      loading.css 'margin', '0 auto'

  removeLoading: (element) ->
    element.removeClass 'loading'
    element.children('span.loading.loading-spinner-medium').remove()
    showChildren element

  addMessage: (element, message, settings={}) ->
    if not settings?.nohide then hideChildren element
    div = $('<div></div>')
    element.append div
    div.addClass 'pros-message'
    if settings?.error
      div.addClass 'error-presenter'
      div.append '<ul class="background-message error-messages">Error!</ul>'
    div.append message
    subscription = atom.tooltips.add div, title: 'Copy Text'
    div.click -> atom.clipboard.write div.text()
    return subscription

  clearMessages: (element) ->
    element.children('.pros-message').remove()
    showChildren element


  createDepotConfig: (location, updateConfig, {name: depot, registrar}) ->
    if not location then location = $('<div></div')
    if not @depotConfigCache then @depotConfigCache = {}
    @applyLoading location
    createBoolParameter = (key, prop, value) ->
      label = $("<label class='depot-input'></label>")
      label.addClass 'input-label'
      label.data 'key', key
      input = $("<input data-key='#{key}' class='input-checkbox' type='checkbox'>
      #{prop.prompt}
      </input>")
      input.click -> updateConfig depot, key, input.is(':checked')
      input.attr 'checked', value ? prop.default ? false
      label.append input
      return label
    createStrParameter = (key, prop, value) ->
      div = $("<div data-key='#{key}' class='depot-input'>#{prop.prompt}</div>")
      editor = new TextEditorView mini: true, placeholderText: prop.default
      if value then editor.getModel().setText value
      editor.getModel().onDidChange -> updateConfig depot, key, editor.getModel().getText()
      div.append editor
    fillDepotConfig = (config) =>
      cli.execute {
        cmd: ['pros', 'conduct', 'info-depot', depot, '--machine-output'],
        cb: (c, o, e) =>
          @removeLoading location
          if c == 0
            settings = {}
            try
              settings = JSON.parse o
            catch err
              @addMessage location,
                "There was an error parsing the configuration: #{o} (#{err})"
                error: true
              return
            location.empty()
            keys = (k for own k, v of config).sort()
            for {k, v} in ({k, v: config[k]} for k in keys)
              if v.method == 'bool'
                location.append createBoolParameter k, v, settings[k]
              else
                location.append createStrParameter k, v, settings[k]
          else
            @addMessage @selectedDepotConfig,
              "There was an error retrieving the depot configuration:
              <br/>STDOUT:<br/>#{o}<br/><br/>ERR:<br/>#{e}"
      }
    if not @depotConfigCache.hasOwnProperty registrar
      cli.execute {
        cmd: ['pros', 'conduct', 'ls-registrars', '--machine-output'],
        cb: (c, o, e) =>
          if c == 0
            try
              Object.assign(@depotConfigCache, JSON.parse o)
              if @depotConfigCache.hasOwnProperty registrar
                fillDepotConfig @depotConfigCache[registrar]
            catch err
              console.error err
          else console.log {c, o, e}
      }
    else
      fillDepotConfig @depotConfigCache[registrar]
