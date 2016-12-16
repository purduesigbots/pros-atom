{CompositeDisposable, Disposable} = require 'atom'
{$, View, ScrollView} = require 'atom-space-pen-views'
cli = require '../cli'
fs = require 'fs-plus'
path = require 'path'
commandExists = require 'command-exists'
brand = require './brand'
utils = require '../utils'
async = require 'async'

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

          @div class: 'error-presenter', =>
            @ul class: 'background-message error-messages', => @raw 'Error!'
            @div outlet: 'errorInfo'

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
              @div class: 'kernel', =>
                @h3 'Kernels'

    libItem: (name, version, latest) ->
      "<li class='#{if latest then 'text-success' else 'text-warning'}'>
        <span class='inline-block-tight icon icon-check'></span>
        <span class='inline-block-tight icon icon-move-up'></span>
        #{name}-#{version}
      </li>"

    initialize: ({@uri, activeProject}={}) ->
      super
      @subscriptions = new CompositeDisposable

      cli.checkCli '2.4.1', (c, o) =>
        # TODO: Make out of date CLI notification prettier
        if c != 0
          $('.pros-conductor > .error-presenter').addClass 'enabled'
          @errorInfo.text "Command `pros` was not found. Visit
          http://pros.cs.purdue.edu/known-issues/#missing-cli to learn more. (#{o})"
          return
        $('.pros-conductor > .error-presenter').removeClass 'enabled'
        @on 'click', '.recent-projects > li', (e) => @updateSelectedPath $(e.target).closest('li').data 'path'

        @subscriptions.add atom.project.onDidChangePaths =>
          prevSelected = @selected?.data 'path'
          @updateAvailableProjects()
          if prevSelected in atom.project.getPaths()
            @updateSelectedPath prevSelected
          else
            @updateSelectedPath atom.project.getPaths()?[0]
        @addExisting.on 'click', => atom.pickFolder((paths) =>
          if paths
            atom.project.addPath p for p in paths
            @updateSelectedPath paths.filter((p) -> fs.existsSync path.join p, 'project.pros')[0] or
              @selected?.data 'path'
          )
        @createNew.on 'click', -> new (require './new-project')
        @addLibraryButton.on 'click', =>
          _path = @selected?.data 'path'
          if _path then new (require './add-library') _path: _path, cb: (complete) =>
            if complete then @updateSelectedPath null
        @updateAvailableProjects()
        @updateSelectedPath activeProject or atom.project.getPaths()?[0]

    updateAvailableProjects: ->
      @projectSelector.empty()
      for project in utils.findOpenPROSProjectsSync()
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
        if not newSelected then newSelected = @projectSelector.children().first()
        @selected?.removeClass 'selected'
        newSelected.addClass 'selected'
        oldPath = @selected?.data 'path'
        @selected = newSelected

        # scroll projectSelector if selected isn't in view
        idx = @projectSelector.children().index(@selected)
        if (idx * @selected.width()) < @projectSelector.scrollLeft() or
           ((idx + 1) * @selected.width()) > (@projectSelector.scrollLeft() + @projectSelector.width())
          @projectSelector.animate { scrollLeft: idx * @selected.width() }, 100

      if @selected?.data('path') == oldPath then return
      @activeProject = project = @selected.data 'path'
      @projectHeader.text "#{path.basename project} (#{project})"
      @projectDiv.addClass 'loading'
      cli.projectInfo(((c, info) =>
        # do it again in case user starts clicking between projects quickly for better appearance
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
        ), project)

    serialize: ->
      deserializer: @constructor.name
      version: 1
      activeProject: @selected?.data 'path'
      uri: @uri

    getURI: -> @uri
    getTitle: -> "Conductor"
    getIconName: -> 'pros'
