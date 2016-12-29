{CompositeDisposable, Disposable} = require 'atom'
{$, View, ScrollView, TextEditorView} = require 'atom-space-pen-views'
cli = require '../cli'
fs = require 'fs-plus'
path = require 'path'
commandExists = require 'command-exists'
brand = require './brand'
utils = require '../utils'
async = require 'async'
std = require './standard'

proscli = require '../proscli'

module.exports =
  class ConductorView extends ScrollView
    @content: ->
      @div class: 'pros-conductor-parent', =>
        @div class: 'ribbon-wrapper', =>
          @div class: 'ribbon', => @raw 'BETA'
        @div class: "pros-conductor", =>
          @div class: "header", =>
            @raw brand.tuxFullColor
            @div class: "title", =>
              @h1 'PROS Conductor'
              @h2 'Project Management'

          std.errorPresenter.call @, outlet: 'conductorErrorInfo'

          @div class: "project-selector", =>
            @button class: 'btn btn-primary icon icon-file-directory-create inline-block-tight',
            outlet: 'createNew',   => @raw 'New Project'
            @button class: 'btn btn-primary icon icon-device-desktop inline-block-tight',
            outlet: 'addExisting', => @raw 'Add Existing'
            @ul class: 'recent-projects', outlet: 'projectSelector'

          @div class: "project loading", outlet: 'projectDiv', =>
            @h2 outlet: 'projectHeader'
            @div =>
              @span outlet: 'projectLoading', class: 'loading loading-spinner-large inline-block'
              std.errorPresenter.call @, outlet: 'projectErrorInfo'
              @div class: 'kernel', =>
                @h3 'Kernel'
                @div =>
                  @div =>
                    @span class: 'inline-block-tight icon icon-check'
                    @span class: 'inline-block-tight icon icon-move-up'
                    @div outlet: 'projectKernel'
                  @div class: 'btn-group', =>
                    @button class: 'inline-block-tight btn icon icon-move-up', => @raw 'Upgrade'

              @div class: 'libraries', =>
                @div =>
                  @h3 'Libraries'
                  @button class: 'inline-block-tight btn icon icon-file-add',
                  outlet: 'addLibraryButton', => @raw 'Add'
                @ul class: 'list-group', outlet: 'projectLibraries'
          @div class: 'global', =>
            @h2 'Global Configuration'
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
                @h3 'Depots'
                @table class: 'list-group', =>
                  @thead =>
                    @td class: 'name', 'Name'
                    @td class: 'location', 'Location'
                    @td class: 'registrar', 'Registrar'
                  @tbody outlet: 'globalDepots'
                @h4 outlet: 'selectedDepotHeader'
                @div outlet: 'selectedDepotConfig'

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
      "<tr class='depot-item' data-name='#{name}' data-registrar='#{registrar}'>
        <td class='name'>#{name}</td>
        <td class='location'>#{location}</td>
        <td class='registrar'>#{registrar}</td>
      </tr>"
    initialize: ({@uri, activeProject}={}) ->
      super
      @subscriptions = new CompositeDisposable

      @subscriptions.add atom.tooltips.add @conductorErrorInfo[0], title: 'Copy Message'
      @conductorErrorInfo.on 'click', => atom.clipboard.write @conductorErrorInfo.text()

      @subscriptions.add atom.tooltips.add @projectErrorInfo[0], title: 'Copy Message'
      @projectErrorInfo.on 'click', => atom.clipboard.write @projectErrorInfo.text()
      proscli.checkCli minVersion: '2.4.1', fmt: 'html', cb: (c, o) =>
        if c != 0
          @conductorErrorInfo.addClass 'enabled'
          @conductorErrorInfo.children('div').html o
          return
        @conductorErrorInfo.removeClass 'enabled'
        @on 'click', '.recent-projects > li', (e) => @updateSelectedPath $(e.target).closest('li').data 'path'

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
            console.log newPROSProjects
            @updateSelectedPath newPROSProjects?[0] or @selected?.data 'path'
        @createNew.on 'click', -> new (require './new-project')
        @addLibraryButton.on 'click', =>
          _path = @selected?.data 'path'
          if _path then new (require './add-library') _path: _path, cb: (complete) =>
            if complete then @updateSelectedPath null

        @updateAvailableProjects()
        activeProject ?= atom.project.getPaths()?[0]
        @updateSelectedPath activeProject

        @updateGlobalListing()

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
    updateSelectedPath: (project) ->
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

      # if @selected?.data('path') == oldPath then return
      @activeProject = project = @selected.data 'path'
      @projectHeader.text "#{path.basename project} (#{project})"
      @projectDiv.addClass 'loading'

      proscli.execute cmd: ['pros', 'conduct', 'info-project', project, '--machine-output'], cb: (c, o, e) =>
        if c == 0
          info = (JSON.parse e) for e in o?.split(/\r?\n/).filter(Boolean)
          @projectErrorInfo.parent().removeClass 'enabled'
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
          @projectDiv.removeClass 'loading'
        else
          console.log {c, o, e}
          div = @projectErrorInfo.children('div')
          div.empty()
          for line in "STDOUT:\n#{o}\n\nERR:\n#{e}".split '\n'
            div.append document.createTextNode line
            div.append '<br/>'
          @projectErrorInfo.addClass 'enabled'
          @projectDiv.removeClass 'loading'


    initializeGlobalListing: ->
      @on 'click', '.global .download-item .icon-cloud-download', (e) =>
        template = $(e.target).closest('tr').data()
        console.log template
        proscli.execute {
          cmd: ['pros', 'conduct', 'download', template.name, template.version, template.depot],
          cb: (c, o, e) =>
            if c == 0
              atom.notifications.addSuccess "Downloaded kernel #{template.version}",
                detail: o,
                dismissable: true
              @updateGlobalListing()
        }
      @on 'click', '.global .depot-item', (e) =>
        @selectedDepot?.removeClass 'selected-depot'
        @selectedDepot = $(e.target).closest 'tr'
        @selectedDepot.addClass 'selected-depot'
        depot = @selectedDepot.data()
        @selectedDepotHeader.text "#{depot.name} (#{depot.registrar})"
        @createDepotConfig depot


    updateGlobalListing: ->
      std.applyLoading @globalLibraryDiv
      proscli.execute {
        cmd: ['pros', 'conduct', 'lstemplate', '--kernels', '--machine-output'],
        cb: (c, o, e) =>
          @globalKernelsDiv.removeClass 'loading'
          if c == 0
            listing = []
            for e in o?.split(/\r?\n/).filter(Boolean)
              try
                listing = listing.concat JSON.parse e
              catch err
                std.addMessage @globalKernelsDiv, "Error parsing: #{e} (#{err})", nohide: true
            # listing = (try JSON.parse e catch error ) for e in o?.split(/\r?\n/).filter(Boolean)
            @globalKernels.empty()
            if listing.length == 0
              std.addMessage @globalKernelsDiv,
                "You don't have any depots which provide kernels.
                Add a depot that provides depots to get started."
            else
              for {version, depot, offline, online} in listing
                @globalKernels.append @globalKernelItem version, depot, offline, online
          else
            std.addMessage @globalLibraryDiv,
              "There was an error fetching the kernels listing:<br/>#{o}<br/>#{e}",
              error: true
      }
      proscli.execute {
        cmd: ['pros', 'conduct', 'lstemplate', '--libraries', '--machine-output'],
        cb: (c, o, e) =>
          std.removeLoading @globalLibraryDiv
          if c == 0
            listing = []
            for e in o?.split(/\r?\n/).filter(Boolean)
              try
                listing = listing.concat JSON.parse e
              catch err
                std.addMessage @globalLibraryDiv, "Error parsing: #{e} (#{err})", nohide: true
            @globalLibraries.empty()
            if listing.length == 0
              std.addMessage @globalLibraryDiv,
                "You don't have any depots which provide libraries.<br/>
                Add a depot that provides depots to get started."
            else
              for {library, version, depot, offline, online} in listing
                @globalLibraries.append @globalLibraryItem library, version, depot, offline, online
          else
            std.addMessage @globalLibraryDiv,
              "There was an error fetching the libraries listing:
              <br/>STDOUT:<br/>#{o}<br/><br/>ERR:<br/>#{e}",
              error: true
      }
      proscli.execute {
        cmd: ['pros', 'conduct', 'ls-depot', '--machine-output'],
        cb: (c, o, e) =>
          std.removeLoading @globalDepotDiv
          if c == 0
            listing = []
            try
              listing = listing.concat JSON.parse o
            catch err
              std.addMessage @globalDepotDiv, "Error parsing: #{e} (#{err})", nohide: true
            @globalDepots.empty()
            if listing.length == 0
              std.addMessage @globalDepotDiv,
                "You don't have any depots configured. Run
                <span class='inline-block highlight'>pros conduct first-run</span> to automatically set up
                the default PROS depot, or restart Atom and it will be automatically configured for you.",
                nohide: true
            else
              for depot in listing
                @globalDepots.append @globalDepotItem depot
          else
            std.addMessage @globalDepotDiv,
              "There was an error fetching the configured depots:
              <br/>STDOUT:<br/>#{o}<br/><br/>ERR:<br/>#{e}",
              error: true
      }

    createDepotConfig: ({depot, registrar}) ->
      if not @depotConfigCache then @depotConfigCache = {}
      createBoolParameter = (key, prop, value) ->
        label = $("<label></label>")
        label.addClass 'input-label'
        label.data 'key', key
        input = $("<input data-key='#{key}' class='depot-input input-checkbox' type='checkbox'>
        #{prop.prompt}
        </input>")
        input.attr 'checked', value ? prop.default ? false
        label.append input
        return label

      createStrParameter = (key, prop, value) ->
        div = $("<div data-key='#{key}' class='depot-input'>#{prop.prompt}</div>")
        editor = new TextEditorView mini: true, placeholderText: prop.default
        if value then editor.getModel().setText value
        div.append editor


      fillDepotConfig = (config) =>
        proscli.execute {
          cmd: ['pros', 'conduct', 'info-depot', depot, '--machine-output'],
          cb: (c, o, e) =>
            if c == 0
              settings = {}
              try
                settings = JSON.parse o
              catch err
                std.addMessage @selectedDepotConfig,
                  "There was an error parsing the configuration: #{o} (#{err})"
                  error: true
                return
              @selectedDepotConfig.empty()
              for k, v of config
                if v.method == 'bool'
                  @selectedDepotConfig.append createBoolParameter k, v, settings[k]
                else
                  @selectedDepotConfig.append createStrParameter k, v, settings[k]
            else
              std.addMessage @selectedDepotConfig,
                "There was an error retrieving the depot configuration:
                <br/>STDOUT:<br/>#{o}<br/><br/>ERR:<br/>#{e}"
        }
        console.log config
      if not @depotConfigCache.hasOwnProperty registrar
        proscli.execute {
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


    serialize: ->
      deserializer: @constructor.name
      version: 1
      activeProject: @selected?.data 'path'
      uri: @uri

    getURI: -> @uri
    getTitle: -> "Conductor"
    getIconName: -> 'pros'
