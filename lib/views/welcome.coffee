{CompositeDisposable, Disposable} = require 'atom'
{$, ScrollView} = require 'atom-space-pen-views'
{BaseView} = require './base-view'
shell = require 'shell'
utils = require '../utils'
cli = require '../cli'
brand = require './brand'

module.exports =
  class WelcomeView extends ScrollView
    @content: ->
      @div class:"pros-welcome", =>
        @div class:"container", =>
          @header class:"header", =>
            @raw brand.tuxFullColor
            @raw brand.text
            @h1 class: "title", => @raw 'Open Source C Development for the VEX Cortex'
          @section class:"panel", =>
            @p 'For help, please visit:'
            @ul =>
              @li =>
                @a outlet: 'gettingStarted', => @raw 'This page'
                @raw ' for a guide to getting started with PROS for Atom.'
              @li =>
                @raw 'The '
                @a outlet: 'tutorials', => @raw 'PROS tutorial page'
                @raw " to learn about using everything from analog sensors to tasks and
                      multithreading in PROS."
              @li =>
                @raw 'The '
                @a outlet: 'api', => @raw 'PROS API documentation'
                @raw '.'
            @div class: 'welcome-settings', =>
              @form =>
                @label =>
                  @input type: 'checkbox', class: 'input-checkbox', id: "pros-welcome-on-startup"
                  @raw 'Show Welcome for PROS when opening Atom'
                @br()
                @label outlet: 'gaInput', =>
                  @input type: 'checkbox', class: 'input-checkbox', id: 'pros-ga-enabled'
                  @raw 'Send anonymous usage statistics'
            @div outlet: 'versions', class: 'versions', =>
              @div () =>
                @div class: 'block', =>
                  @raw 'CLI: '
                  @span class: 'badge badge-flexible', outlet: 'cliVersion', =>
                    @span class: 'loading loading-spinner-tiny inline-block'
                @div class: 'block', =>
                  @raw 'Plugin: '
                  @span class: 'badge badge-flexible', outlet: 'pkgVersion', =>
                    @span class: 'loading loading-spinner-tiny inline-block'
          @footer class:"footer", =>
            @a outlet: 'home', => @raw 'pros.cs.purdue.edu'
            @span class: 'text-subtle', => @raw 'ｘ'
            @a outlet: 'github', class: 'icon icon-octoface'

    initialize: ->
      @subscriptions = new CompositeDisposable
      @gettingStarted[0].onclick =-> shell.openExternal 'http://pros.cs.purdue.edu/getting-started'
      @tutorials[0].onclick =-> shell.openExternal 'http://pros.cs.purdue.edu/tutorials'
      @api[0].onclick =-> shell.openExternal 'http://pros.cs.purdue.edu/api'
      @home[0].onclick =-> shell.openExternal 'http://pros.cs.purdue.edu'
      @github[0].onclick =-> shell.openExternal 'https://github.com/purduesigbots'

      $(this).find('#pros-welcome-on-startup').prop('checked', atom.config.get 'pros.welcome.enabled')
      $(this).find('#pros-welcome-on-startup').click =>
        atom.config.set 'pros.welcome.enabled',
          $(this).find('#pros-welcome-on-startup').prop 'checked'

      $(this).find('#pros-ga-enabled').prop('checked', atom.config.get 'pros.googleAnalytics.enabled')
      $(this).find('#pros-ga-enabled').click =>
        atom.config.set 'pros.googleAnalytics.enabled',
          $(this).find('#pros-ga-enabled').prop 'checked'

      cliVer = 'Loading'
      cli.execute ((c, o) =>
        cliVer = @cliVersion[0].textContent = /pros, version (.*)/g.exec(o)?[1]
        @cliVersion.removeClass 'badge-error'
        if !!!cliVer
          cliVer = @cliVersion[0].textContent = 'Not found'
          @cliVersion.addClass 'badge-error'
        ), cli.baseCommand '--version'
      pkgVer = @pkgVersion[0].textContent = require('../../package.json').version
      @versions[0].onclick = -> atom.clipboard.write "PROS CLI: #{cliVer} - Package: #{pkgVer}"

      @subscriptions.add atom.tooltips.add @gaInput,
      {
        title: "We send anonymous analytics on startup of Atom.<br/>
        To disable, uncheck this box or disable telemetry within Atom"
      }
      @subscriptions.add atom.tooltips.add @versions[0], {title: 'Copy version info'}

    getURI: -> @uri
    getTitle: -> "Welcome"
    getIconName: -> 'pros'

# coffeelint: enable=max_line_length
