{$} = require 'atom-space-pen-views'

module.exports =
  errorPresenter: (settings) ->
    @div Object.assign(settings, class: 'error-presenter'), =>
      @ul class: 'background-message error-messages', => @raw 'Error!'
      @div()

  applyLoading: (element) ->
    if not element.hasClass 'loading'
      element.addClass 'loading'
      element.children().not(element.children ':header').hide()
      loading = element.append "<span class='loading loading-spinner-medium'></span>"
      loading.css 'margin', '0 auto'

  removeLoading: (element) ->
    element.removeClass 'loading'
    element.children('span.loading.loading-spinner-medium').remove()
    element.children().show()

  addMessage: (element, message, settings={}) ->
    if not settings?.nohide
      element.children().not(element.children ':header').not(element.children '.header').hide()
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
    element.children().show()
