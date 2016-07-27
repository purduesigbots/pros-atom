fs = require 'fs'
path = require 'path'

module.exports =
  BaseView: class BaseView
    panel: null

    constructor: (file) ->
      file ?= __dirname
      content = fs.readFileSync path.join(file, 'view.html')
      parser = new DOMParser
      @element = (parser.parseFromString content, 'text/html')
      .querySelector('div')

    toggle: ->
      if @panel?.isVisible()
        @hide()
      else
        @show()

    show: ->
      @panel ?= atom.workspace.addModalPanel(item: this)
      @panel.show()

    hide: ->
      @panel?.hide()

    isVisible: ->
      @panel?.isVisible()

    # A static method to register
    @register: ->
      atom.views.addViewProvider this, (m) ->
        unless m instanceof this
          m = new this
        return m.element
