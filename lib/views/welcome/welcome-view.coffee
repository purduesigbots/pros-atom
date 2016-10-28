{Disposable} = require 'atom'
{$, ScrollView} = require 'atom-space-pen-views'
{BaseView} = require '../base-view'
shell = require 'shell'

module.exports =
  class WelcomeView extends ScrollView
    @content: ->
      @div class:"pros-welcome", =>
        @div class:"container", =>
          @header class:"header", =>
            @a class: 'hero', outlet: 'header', =>
              # coffeelint: disable=max_line_length
              @raw "<svg version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" x=\"0px\" y=\"0px\" width=\"179.991px\" height=\"157.491px\" viewBox=\"0 0 179.991 157.491\" xml:space=\"preserveAspectRatio\"><g><g><g><polygon fill-rule=\"evenodd\" clip-rule=\"evenodd\" fill=\"#D2AB67\" points=\"118.856,43.466 134.055,56.623 89.944,95.067 89.944,95.044 89.857,95.12 45.936,56.838 61.157,43.572 89.97,85.831 \"/></g><g><polygon fill-rule=\"evenodd\" clip-rule=\"evenodd\" fill=\"#E7BC70\" points=\"90.004,95.015 134.055,56.623 118.856,43.466 90.004,85.781 \"/></g><polygon fill-rule=\"evenodd\" clip-rule=\"evenodd\" fill=\"#D2AB67\" points=\"127.35,27.55 89.97,82.374 52.59,27.55 89.97,6.295 \"/><path fill=\"#E7BC70\" d=\"M90.004,82.323l37.345-54.773l-6.01,8.648H90.004V82.323z M101.99,58.773l-0.293-19.644l19.35-2.785L101.99,58.773z\"/><polygon fill=\"#E7BC70\" points=\"90.004,6.314 90.004,16.573 92.901,18.021 92.901,20.953 90.004,22.402 90.004,27.55 127.349,27.55 \"/><polygon fill-rule=\"evenodd\" clip-rule=\"evenodd\" fill=\"#060500\" points=\"127.35,27.55 89.97,73.579 52.59,27.55 89.97,10.692 \"/><polygon fill-rule=\"evenodd\" clip-rule=\"evenodd\" fill=\"#2F2D29\" points=\"90.004,10.692 89.97,10.708 89.97,73.537 90.004,73.579 127.384,27.55 \"/><polygon fill-rule=\"evenodd\" clip-rule=\"evenodd\" fill=\"#D2AB67\" points=\"58.6,36.198 121.34,36.198 127.35,27.55 52.59,27.55 \"/><polygon fill=\"#E7BC70\" points=\"90.004,27.55 90.004,36.198 121.339,36.198 127.349,27.55 \"/><polygon fill-rule=\"evenodd\" clip-rule=\"evenodd\" fill=\"#060500\" points=\"111.079,31.801 68.861,31.801 65.929,27.403 114.011,27.403 \"/><polygon fill-rule=\"evenodd\" clip-rule=\"evenodd\" fill=\"#2F2D29\" points=\"89.97,27.403 89.97,31.801 111.113,31.801 114.045,27.403 \"/><polygon fill-rule=\"evenodd\" clip-rule=\"evenodd\" fill=\"#7E868C\" points=\"67.982,30.335 68.861,31.801 111.079,31.801 111.958,30.335 \"/><circle fill-rule=\"evenodd\" clip-rule=\"evenodd\" fill=\"#7E868C\" cx=\"89.97\" cy=\"39.57\" r=\"1.173\"/><circle fill-rule=\"evenodd\" clip-rule=\"evenodd\" fill=\"#7E868C\" cx=\"89.97\" cy=\"44.7\" r=\"1.173\"/><circle fill-rule=\"evenodd\" clip-rule=\"evenodd\" fill=\"#7E868C\" cx=\"89.97\" cy=\"49.685\" r=\"1.173\"/><polygon fill-rule=\"evenodd\" clip-rule=\"evenodd\" fill=\"#D2AB67\" points=\"77.95,58.626 78.243,39.13 58.747,36.198 \"/><polygon fill-rule=\"evenodd\" clip-rule=\"evenodd\" fill=\"#060500\" points=\"77.95,58.626 72.966,44.114 58.747,36.198 \"/><polygon fill-rule=\"evenodd\" clip-rule=\"evenodd\" fill=\"#D2AB67\" points=\"101.991,58.773 101.697,39.13 121.046,36.345 \"/><polygon fill=\"#E7BC70\" points=\"101.697,39.13 101.99,58.773 121.046,36.345 \"/><polygon fill-rule=\"evenodd\" clip-rule=\"evenodd\" fill=\"#2F2D29\" points=\"101.991,58.773 107.121,44.114 121.046,36.345 \"/><polygon fill-rule=\"evenodd\" clip-rule=\"evenodd\" fill=\"#D2AB67\" points=\"92.902,20.953 89.97,22.419 87.039,20.953 87.039,18.021 89.97,16.556 92.902,18.021 \"/><polygon fill=\"#E7BC70\" points=\"90.004,16.573 90.004,22.402 92.901,20.953 92.901,18.021 \"/><path fill-rule=\"evenodd\" clip-rule=\"evenodd\" fill=\"#7E868C\" d=\"M90.703,76.656c0,0.294-0.292,0.588-0.586,0.588h-0.294c-0.292,0-0.586-0.294-0.586-0.588v-22.28c0-0.294,0.294-0.587,0.586-0.587h0.294c0.294,0,0.586,0.293,0.586,0.587V76.656z\"/></g><g><path fill=\"#fff\" d=\"M40.903,115.341c0,7.815-4.878,12.362-13.356,12.362h-5.92v9.188h-8.667V103.69h14.588C36.024,103.69,40.903,107.952,40.903,115.341z M32.662,115.626c0-3.269-2.037-5.021-5.542-5.021h-5.494v10.184h5.494C30.625,120.788,32.662,118.988,32.662,115.626z\"/><path fill=\"#fff\" d=\"M73.552,136.892l-4.831-9.188h-0.189h-6.252v9.188h-8.667V103.69h14.919c8.81,0,13.83,4.262,13.83,11.65c0,5.021-2.084,8.715-5.92,10.705l6.915,10.846H73.552z M62.279,120.788h6.299c3.505,0,5.542-1.8,5.542-5.162c0-3.269-2.037-5.021-5.542-5.021h-6.299V120.788z\"/><path fill=\"#fff\" d=\"M130.119,120.267c0,9.71-7.672,17.004-17.95,17.004s-17.951-7.294-17.951-17.004c0-9.662,7.673-16.813,17.951-16.813S130.119,110.652,130.119,120.267z M103.123,120.314c0,5.399,4.215,9.567,9.141,9.567c4.973,0,8.951-4.168,8.951-9.567s-3.979-9.473-8.951-9.473S103.123,114.915,103.123,120.314z\"/><path fill=\"#fff\" d=\"M155.048,110.368c-2.084,0-3.458,0.758-3.458,2.273c0,5.494,17.478,2.368,17.478,14.304c0,6.772-5.969,10.23-13.357,10.23c-5.541,0-11.319-2.036-15.298-5.305l3.362-6.772c3.41,2.936,8.573,5.02,12.031,5.02c2.557,0,4.168-0.947,4.168-2.699c0-5.637-17.478-2.227-17.478-13.973c0-6.204,5.257-10.135,13.262-10.135c4.878,0,9.804,1.516,13.262,3.741l-3.269,6.868C162.248,111.931,157.794,110.368,155.048,110.368z\"/></g></g></svg>"
            @h1 class:"title", => @raw 'Open Source C Development for the VEX Cortex'
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
                @label =>
                  @input type: 'checkbox', class: 'input-checkbox', id: 'pros-ga-enabled'
                  @raw 'Send anonymous usage statistics'
          @footer class:"footer", =>
            @a outlet: 'home', => @raw 'pros.cs.purdue.edu'
            @span class: 'text-subtle', => @raw 'ｘ'
            @a outlet: 'github', class: 'icon icon-octoface'

    initialize: ->
      @header[0].onclick =-> shell.openExternal 'http://pros.cs.purdue.edu'
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

    @deserialize: (options={}) ->
      new WelcomeView(options)

    serialize: ->
      deserializer: @constructor.name
      uri: @getURI()

    getURI: ->
      @uri

    getTitle: ->
      "Welcome"

# coffeelint: enable=max_line_length
