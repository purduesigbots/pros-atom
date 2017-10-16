{CompositeDisposable, Disposable} = require 'atom'
{$, View, ScrollView, TextEditorView} = require 'atom-space-pen-views'
fs = require 'fs-plus'
path = require 'path'
commandExists = require 'command-exists'
brand = require './brand'
utils = require '../utils'
async = require 'async'
std = require './standard'

cli = require '../proscli'
{prosConduct} = cli

module.exports =
  class ConductorView extends ScrollView
    @content: ->
      @div class: 'pros-conductor-parent', =>
        @div class: 'ribbon-wrapper', =>
          @div class: 'ribbon', => @raw 'BETA'
        @div class: "pros-conductor", outlet: 'conductorDiv', =>
          @div class: "header", =>
            @raw brand.tuxFullColor
            @div class: "title", =>
              @h1 'PROS Conductor'
              @h2 'Project Management'

          @div class: "project-selector", =>
            @button class: 'btn btn-primary icon icon-file-directory-create inline-block-tight',
            outlet: 'createNew',   => @raw 'New Project'
            @button class: 'btn btn-primary icon icon-device-desktop inline-block-tight',
            outlet: 'addExisting', => @raw 'Add Existing'
            @ul class: 'recent-projects', outlet: 'projectSelector'

          @div class: "project", outlet: 'projectDiv', =>
            @h2 outlet: 'projectHeader'
            @div =>
              @div class: 'kernel', =>
                @h3 'Kernel'
                @div =>
                  @div =>
                    @span class: 'inline-block-tight icon icon-check'
                    @span class: 'inline-block-tight icon icon-move-up'
                    @div outlet: 'projectKernel'
                  @div class: 'btn-group', =>
                    @button class: 'inline-block-tight btn icon icon-move-up', outlet: 'upgradeProjectButton',
                      => @raw 'Upgrade'
              @div class: 'libraries', =>
                @div =>
                  @h3 'Libraries'
                  @button class: 'inline-block-tight btn icon icon-file-add',
                  outlet: 'addLibraryButton', => @raw 'Add'
                @ul class: 'list-group', outlet: 'projectLibraries'
          @hr()
          @div class: 'global', outlet: 'globalDiv', =>
            @div class: 'header', =>
              @h2 'Global Configuration'
              @div class: 'btn-group', =>
                @button outlet: 'refreshGlobal', class: 'btn btn-sm icon icon-sync'
            @div =>
              @div class: 'kernel', outlet: 'globalKernelsDiv', =>
                @h3 'Kernels'
                @table class: 'list-group', =>
                  @thead =>
                    @td class: 'version', 'Version'
                    @td class: 'depot', 'Depot'
                    @td()
                    @td()
                  @tbody outlet: 'globalKernels'
              @div class: 'libraries', outlet: 'globalLibraryDiv', =>
                @h3 'Libraries'
                @table class: 'list-group', =>
                  @thead =>
                    @td class: 'name', 'Name'
                    @td class: 'version', 'Version'
                    @td class: 'depot', 'depot'
                    @td()
                    @td()
                  @tbody outlet: 'globalLibraries'
              @div class: 'depots', outlet: 'globalDepotDiv', =>
                @div class: 'header', =>
                  @h3 'Depots'
                  @div class: 'btn-group btn-group-sm', =>
                    @button class: 'btn icon icon-file-add',
                    outlet: 'addDepotButton', => @raw 'Add'
                    @button class: 'btn icon icon-trashcan', disabled: true,
                    outlet: 'removeDepotButton', => @raw 'Remove'
                @ul class: 'list-group', outlet: 'globalDepots'
                @h4 outlet: 'selectedDepotHeader'
                @span outlet: 'selectedDepotStatus', class: 'inline-block depot-status icon icon-check'
                @div class:'depot-config', outlet: 'selectedDepotConfig'

    libItem: (name, version, latest) ->
      "<li class='#{if latest then 'text-success' else 'text-warning'}'>
        <span class='inline-block-tight icon icon-check'></span>
        <span class='inline-block-tight icon icon-move-up'></span>
        #{name}-#{version}
      </li>"

    globalKernelItem: (version, depot, offline, online) ->
      "<tr class='download-item' data-name='kernel' data-version='#{version}' data-depot='#{depot}'>
        <td class='version'>#{version}</td>
        <td class='depot'>#{depot}</td>
        <td class='offline'>
          #{if offline then "<span class='inline-block-tight icon icon-device-desktop'></span>" else ""}
        </td>
        <td class='online'>
          #{if online then "<span class='inline-block-tight icon icon-cloud-download'></span>" else ""}
        </td>
      </tr>"

    globalLibraryItem: (name, version, depot, offline, online) ->
      "<tr class='download-item' data-name='#{name}' data-version='#{version}' data-depot='#{depot}'>
        <td class='name'>#{name}</td>
        <td class='version'>#{version}</td>
        <td class='depot'>#{depot}</td>
        <td class='offline'>
          #{if offline then "<span class='inline-block-tight icon icon-device-desktop'></span>" else ""}
        </td>
        <td class='online'>
          #{if online then "<span class='inline-block-tight icon icon-cloud-download'></span>" else ""}
        </td>
      </tr>"

    globalDepotItem: ({name, location, registrar}) ->
      li = $("<li class='depot-item list-item'>#{name}<span class='location'>#{location}</span></li>")
      li.data {name, location, registrar}

    initialize: ({@uri, activeProject, activeDepot}={}) ->
      super
      @subscriptions = new CompositeDisposable

      std.applyLoading @globalDiv
      std.applyLoading @projectDiv

      cli.checkCli minVersion: '2.4.1', fmt: 'html', cb: (c, o) =>
        if c != 0
          @subscriptions.add std.addMessage @conductorDiv, o, error: true
          return
        std.clearMessages @conductorDiv
        # @conductorErrorInfo.removeClass 'enabled'
        @on 'click', '.recent-projects > li', (e) =>
          @updateSelectedPath $(e.target).closest('li').data('path'), true

        @initializeGlobalListing()

        @subscriptions.add atom.project.onDidChangePaths =>
          prevSelected = @selected?.data 'path'
          @updateAvailableProjects()
          if prevSelected in atom.project.getPaths()
            @updateSelectedPath prevSelected
          else
            @updateSelectedPath atom.project.getPaths()?[0]
        @addExisting.on 'click', => atom.pickFolder (paths) =>
          if paths
            oldPROSProjects = utils.findOpenPROSProjectsSync()
            atom.project.addPath p for p in paths
            newPROSProjects = utils.findOpenPROSProjectsSync().filter (p) -> p not in oldPROSProjects
            # console.log newPROSProjects
            @updateSelectedPath newPROSProjects?[0] or @selected?.data 'path'
        @createNew.on 'click', => new (require './new-project') cb: (complete, path) =>
          # process.nextTick to let onDidChangePaths process
          if complete then process.nextTick => @updateSelectedPath path
        @addLibraryButton.on 'click', =>
          _path = @selected?.data 'path'
          if _path then new (require './add-library') _path: _path, cb: (complete) =>
            if complete then @updateSelectedPath null, true
        @upgradeProjectButton.on 'click', =>
          _path = @selected?.data 'path'
          if _path then new (require './upgrade-project') dir: _path, cb: (complete) =>
            if complete then @updateSelectedPath null, true

        @updateAvailableProjects()
        activeProject ?= atom.project.getPaths()?[0]
        @updateSelectedPath activeProject
        std.removeLoading @globalDiv
        @updateGlobalKernels()
        @updateGlobalLibraries()
        @updateGlobalDepots activeDepot

    updateAvailableProjects: ->
      projects = utils.findOpenPROSProjectsSync()
      @projectSelector.empty()
      for project in projects
        @projectSelector.append "<li data-path='#{project}'><div>
          <div class='name'>#{path.basename project}</div>
          <div class='dir'>#{path.dirname project}</div>
        </div></li>"
        @subscriptions.add atom.tooltips.add @projectSelector.children().last(), title: project

    # does all the necessary view updates when the project path is changed. What normally would happen if
    # used data binding
    updateSelectedPath: (project, forceUpdate=false) ->
      if not project and not @selected
        $('.pros-conductor .project').addClass 'disabled'
        return
      if project
        $('.pros-conductor .project').removeClass 'disabled'
        newSelected = @projectSelector.children 'li[data-path="' + project.replace(/\\/g, "\\\\") + '"]'
        if not newSelected or newSelected.length == 0
          newSelected = @projectSelector.children().first()
        @selected?.removeClass 'selected'
        newSelected.addClass 'selected'
        oldPath = @selected?.data 'path'
        @selected = newSelected

        # scroll projectSelector if selected isn't in view
        idx = @projectSelector.children().index(@selected)
        if (idx * @selected.width()) < @projectSelector.scrollLeft() or
           ((idx + 1) * @selected.width()) > (@projectSelector.scrollLeft() + @projectSelector.width())
          @projectSelector.animate { scrollLeft: idx * @selected.width() }, 100

      if @selected?.data('path') == oldPath and not forceUpdate then return
      @activeProject = project = @selected.data 'path'
      @projectHeader.text "#{path.basename project} (#{project})"
      std.applyLoading @projectDiv
      cli.execute {
        cmd: prosConduct('info-project', project, '--machine-output'),
        cb: (c, o, e) =>
          if c == 0
            info = (JSON.parse e) for e in o?.split(/\r?\n/).filter(Boolean)
            std.clearMessages @projectDiv
            # @projectErrorInfo.parent().removeClass 'enabled'
            # set active project again in case user starts clicking between projects quickly
            @activeProject = project = @selected.data 'path'
            @projectHeader.text "#{path.basename project} (#{project})"
            @projectKernel.text info.kernel
            if info.kernelUpToDate
              @projectKernel.parent().addClass 'text-success'
              @projectKernel.parent().removeClass 'text-warning'
            else
              @projectKernel.parent().addClass 'text-warning'
              @projectKernel.parent().removeClass 'text-success'

            @projectLibraries.empty()

            if Object.keys(info.libraries).some((k) -> info.libraries.hasOwnProperty k)
              for n, v of info.libraries
                @projectLibraries.append @libItem n, v.version, v.latest
            else
              @projectLibraries.append "<ul class='background-message'>No libraries added</ul>"
            std.removeLoading @projectDiv
          else
            std.removeLoading @projectDiv
            @subscriptions.add std.addMessage @projectDiv, "STDOUT:\n#{o}\n\nERR:\n#{e}", error: true
      }

    initializeGlobalListing: ->
      @selectedDepotStatus.hide()
      @on 'click', '.global .download-item .icon-cloud-download', (e) =>
        template = $(e.target).closest('tr').data()
        cli.execute {
          cmd: prosConduct('download', template.name, template.version, template.depot),
          cb: (c, o, e) =>
            if c == 0
              atom.notifications.addSuccess "Downloaded #{template.name} #{template.version}"
              @updateGlobalLibraries()
        }
      @on 'click', '.global .depot-item', (e) =>
        @selectedDepotStatus.show()
        @selectedDepotStatus.removeClass 'icon-sync icon-stop'
        @selectedDepotStatus.addClass 'icon-check'
        @selectedDepot?.removeClass 'selected-depot'
        @selectedDepot = $(e.target).closest 'li'
        @selectedDepot.addClass 'selected-depot'
        depot = @selectedDepot.data()
        @removeDepotButton.prop 'disabled', depot.name == 'pros-mainline'
        @selectedDepotHeader.text "#{depot.name} uses #{depot.registrar} at #{depot.location}"
        std.createDepotConfig @selectedDepotConfig, @updateDepotConfig, depot
      @addDepotButton.click =>
        new (require './add-depot') cb: ({complete, name}) =>
          if complete
            @updateGlobalKernels()
            @updateGlobalLibraries()
            @updateGlobalDepots name
      @removeDepotButton.click =>
        cli.execute {
          cmd: prosConduct('rm-depot', '--name', @selectedDepot.data 'name'),
          cb: (c, o, e) =>
            if c != 0
              atom.notifications.addError "Failed to remove #{@selectedDepot.data 'name'}",
                detail: "OUT:\n#{o}\n\nERR:\n#{e}",
                dismissable: true
            else
              atom.notifications.addSuccess "Successfully removed #{@selectedDepot.data 'name'}"
              @updateGlobalDepots @selectedDepot?.data 'name'
              @updateGlobalKernels()
              @updateGlobalLibraries()
        }
      @refreshGlobal.click =>
        @updateGlobalKernels()
        @updateGlobalLibraries()
        @updateGlobalDepots @selectedDepot?.data 'name'


    updateGlobalKernels: ->
      std.applyLoading @globalKernelsDiv
      cli.execute {
        cmd: prosConduct('lstemplate', '--kernels', '--machine-output'),
        cb: (c, o, e) =>
          std.removeLoading @globalKernelsDiv
          std.clearMessages @globalKernelsDiv
          if c == 0
            listing = []
            for e in o?.split(/\r?\n/).filter(Boolean)
              try
                listing = listing.concat JSON.parse e
              catch err
                @subscriptions.add std.addMessage @globalKernelsDiv, "Error parsing: #{e} (#{err})",
                  nohide: true
            # listing = (try JSON.parse e catch error ) for e in o?.split(/\r?\n/).filter(Boolean)
            @globalKernels.empty()
            if listing.length == 0
              @subscriptions.add std.addMessage @globalKernelsDiv,
                "You don't have any depots which provide kernels.
                Add a depot that provides libraries to get started."
            else
              for {version, depot, offline, online} in listing
                @globalKernels.append @globalKernelItem version, depot, offline, online
          else
            @subscriptions.add std.addMessage @globalLibraryDiv,
              "There was an error fetching the kernels listing:<br/>#{o}<br/>#{e}",
              error: true
      }

    updateGlobalLibraries: ->
      std.applyLoading @globalLibraryDiv
      cli.execute {
        cmd: prosConduct('lstemplate', '--libraries', '--machine-output'),
        cb: (c, o, e) =>
          std.removeLoading @globalLibraryDiv
          std.clearMessages @globalLibraryDiv
          if c == 0
            listing = []
            for e in o?.split(/\r?\n/).filter(Boolean)
              try
                listing = listing.concat JSON.parse e
              catch err
                @subscriptions.add std.addMessage @globalLibraryDiv, "Error parsing: #{e} (#{err})",
                nohide: true
            @globalLibraries.empty()
            if listing.length == 0
              @subscriptions.add std.addMessage @globalLibraryDiv,
                "You don't have any depots which provide libraries.<br/>
                Add a depot that provides depots to get started."
            else
              for {library, version, depot, offline, online} in listing
                @globalLibraries.append @globalLibraryItem library, version, depot, offline, online
          else
            @subscriptions.add std.addMessage @globalLibraryDiv,
              "There was an error fetching the libraries listing:
              <br/>STDOUT:<br/>#{o}<br/><br/>ERR:<br/>#{e}",
              error: true
      }

    updateGlobalDepots: (prevSelected) ->
      # console.log prevSelected
      std.applyLoading @globalDepotDiv
      cli.execute {
        cmd: prosConduct('ls-depot', '--machine-output'),
        cb: (c, o, e) =>
          std.removeLoading @globalDepotDiv
          if c == 0
            listing = []
            try
              listing = listing.concat JSON.parse o
            catch err
              @subscriptions.add std.addMessage @globalDepotDiv, "Error parsing: #{e} (#{err})", nohide: true
            @globalDepots.empty()
            if listing.length == 0
              @subscriptions.add std.addMessage @globalDepotDiv,
                "You don't have any depots configured. Run
                <span class='inline-block highlight'>pros conduct first-run</span> to automatically set up
                the default PROS depot, or restart Atom and it will be automatically configured for you.",
                nohide: true
            else
              for depot in listing
                item = @globalDepotItem depot
                @globalDepots.append item
                if depot.name == prevSelected
                  prevSelected = null
                  item.click()
              if prevSelected != null
                @globalDepots.children().first().click()
          else
            @subscriptions.add std.addMessage @globalDepotDiv,
              "There was an error fetching the configured depots:
              <br/>STDOUT:<br/>#{o}<br/><br/>ERR:<br/>#{e}",
              error: true
      }

    updateDepotCount: 0
    updateDepotConfig: (depot, key, value) =>
      @selectedDepotStatus.removeClass 'icon-check icon-stop'
      @selectedDepotStatus.addClass 'icon-sync'
      @updateDepotCount += 1
      cli.execute {
        cmd: prosConduct('set-depot-key', depot.toString(), key.toString(), value.toString()),
        cb: (c, o, e) =>
          std.clearMessages @selectedDepotConfig
          if c != 0
            std.addMessage @selectedDepotConfig,
              "Error setting #{key} to #{value}<br/>STDOUT:<br/>#{o}<br/><br/>ERR:<br/>#{e}",
              nohide: true
            @selectedDepotStatus.removeClass 'icon-check icon-sync'
            @selectedDepotStatus.addClass 'icon-stop'
            return
          @updateDepotCount -= 1
          if @updateDepotCount == 0
            @selectedDepotStatus.removeClass 'icon-stop icon-sync'
            @selectedDepotStatus.addClass 'icon-check'
            @updateGlobalKernels()
            @updateGlobalLibraries()
      }

    serialize: ->
      deserializer: @constructor.name
      version: 1
      activeProject: @selected?.data 'path'
      activeDepot: @selectedDepot?.data 'name'
      uri: @uri

    getURI: -> @uri
    getTitle: -> "Conductor"
    getIconName: -> 'pros'
