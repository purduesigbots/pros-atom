{CompositeDisposable, Disposable} = require 'atom'
{$, ScrollView} = require 'atom-space-pen-views'
{BaseView} = require './base-view'
shell = require 'shell'
utils = require '../utils'
cli = require '../proscli'
brand = require './brand'
std = require './standard'

module.exports =
  class WelcomeView extends ScrollView
    @content: ->
      @div class:"pros-welcome", =>
        @div class:"container", =>
          @header class:"header", =>
            @raw brand.tuxFullColor
            @raw brand.text
            @h1 class: "title", => @raw 'Open Source C Development for the VEX Cortex'
          @section class: 'cli-update', outlet: 'cliUpdateOutlet'
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
                  @span 'CLI: '
                  @span class: 'badge badge-flexible', outlet: 'cliVersion', =>
                    @span class: 'loading loading-spinner-tiny inline-block', style: 'margin: auto'
                @div class: 'block', =>
                  @span 'Plugin: '
                  @span class: 'badge badge-flexible', outlet: 'pkgVersion', =>
                    @span class: 'loading loading-spinner-tiny inline-block'
          @footer class:"footer", =>
            @a outlet: 'home', => @raw 'pros.cs.purdue.edu'
            @span class: 'text-subtle', => @raw '×'
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

      @checkCli()
      pkgVer = @pkgVersion[0].textContent = atom.packages.getLoadedPackage('pros').metadata.version
      @versions[0].onclick = -> atom.clipboard.write "PROS CLI: #{@cliVersion.text()} - Package: #{pkgVer}"

      @subscriptions.add atom.tooltips.add @gaInput,
      {
        title: "We send anonymous analytics on startup of Atom to track active users.<br/>
        To disable, uncheck this box or disable telemetry within Atom"
      }
      @subscriptions.add atom.tooltips.add @versions[0], {title: 'Copy version info'}

    checkCli: (refresh=false) ->
      @cliUpdateSubscriptions?.dispose()
      @cliUpdateSubscriptions = new CompositeDisposable
      minVersion = atom.packages.getLoadedPackage('pros').metadata.cli_pros.version
      @cliVersion.removeClass 'badge-error'
      @cliVersion.html "<span class='loading loading-spinner-tiny inline-block' style='margin: auto'></span>"
      @cliUpdateOutlet.removeClass 'info error'
      @cliUpdateOutlet.empty()
      if refresh then std.applyLoading @cliUpdateOutlet else @cliUpdateOutlet.hide()
      cli.checkCli minVersion: minVersion, fmt: 'raw', force: refresh, cb: (c, o) =>
        @cliUpdateOutlet.show()
        std.removeLoading @cliUpdateOutlet
        switch c
          when 0
            @cliVersion.text o.version
            if refresh
              atom.notifications.addSuccess 'PROS CLI is now up to date'
          when 1
            @cliVersion.text o.version
            @cliVersion.addClass 'badge-error'
            @cliUpdateOutlet.addClass 'info'
            # coffeelint: disable=max_line_length
            @cliUpdateOutlet.html "<div>
              <span class='icon icon-info'></span>
              <div>
                PROS CLI is out of date! Some features may not be available.
                 Update to #{minVersion} to get the latest features and bugfixes.
              </div>
              <div class='actions'>
                <div class='btn-group'>
                  <button class='btn btn-primary icon icon-cloud-download' id='downloadPROSUpdate'>
                    Install
                  </button>
                  <button class='btn icon icon-sync' id='refreshPROSCLI'>
                    Refresh
                  </button>
                </div>
              </div>
            </div>"
            @cliUpdateOutlet.find('#downloadPROSUpdate').click -> cli.invUpgrade cb: (c, o, e) ->
              console.log {c, o, e}
            @cliUpdateOutlet.find('#refreshPROSCLI').click => @checkCli true
            # coffeelint: enable=max_line_length
          when 2
            @cliVersion.text 'Error!'
            @cliVersion.addClass 'badge-error'
            @cliUpdateOutlet.addClass 'error'
            # coffeelint: disable=max_line_length
            @cliUpdateOutlet.html "<div>
              <span class='icon icon-stop'></span>
              <div>
                PROS CLI was not found on your PATH!<br/>
                Make sure PROS CLI is installed and available on PATH.
              </div>
              <div class='actions'>
              <div class='btn-group'>
                  <button class='btn btn-primary icon icon-sync' id='restartAtomButton'>
                    Restart Atom
                  </button>
                  <button class='btn btn-primary icon icon-globe' id='goToTroubleshootingPath'>
                    Learn more
                  </button>
                </div>
              </div>
            </div>"
            # coffeelint: enable=max_line_length
            @cliUpdateOutlet.find('#goToTroubleshootingPath').click ->
              shell.openExternal 'http://pros.cs.purdue.edu/known-issues'
            @cliUpdateOutlet.find('#restartAtomButton').click -> atom.restartApplication()
          when 3
            @cliVersion.text 'Error!'
            @cliVersion.addClass 'badge-error'
            @cliUpdateOutlet.addClass 'error'
            # coffeelint: disable=max_line_length
            @cliUpdateOutlet.html "<div>
              <span class='icon icon-stop'></span>
              <div>
                PROS CLI threw an error before returning the version.<br/>
                Visit <a href='http://pros.cs.purdue.edu/known-issues'>pros.cs.purdue.edu/known-issues</a> for troubleshooting steps
              </div>
              <div class='actions'>
                <div class='btn-group'>
                  <button class='btn btn-primary icon icon-globe' id='goToTroubleshootingPath'></button>
                  <button class='btn icon icon-clippy' id='copyOutput'></button>
                  <button class='btn icon icon-sync' id='refreshPROSCLI'></button>
                </div>
              </div>
            </div>"
            # coffeelint: enable=max_line_length
            @cliUpdateSubscriptions.add atom.tooltips.add @cliUpdateOutlet.find('#goToTroubleshootingPath'), title: 'Learn more'
            @cliUpdateSubscriptions.add atom.tooltips.add @cliUpdateOutlet.find('#copyOutput'), title: 'Copy output'
            @cliUpdateSubscriptions.add atom.tooltips.add @cliUpdateOutlet.find('#refreshPROSCLI'), title: 'Refresh'
            @cliUpdateOutlet.find('#goToTroubleshootingPath').click ->
              shell.openExternal 'http://pros.cs.purdue.edu/known-issues'
            @cliUpdateOutlet.find('#copyOutput').click ->
              atom.clipboard.write "PROS CLI failed to return a version.#{(require 'os').EOL}#{o.extra}"
            @cliUpdateOutlet.find('#refreshPROSCLI').click => @checkCli true
          else
            @cliVersion.text 'Error!'
            @cliVersion.addClass 'badge-error'

    getURI: -> @uri
    getTitle: -> "Welcome"
    getIconName: -> 'pros'
