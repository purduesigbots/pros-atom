{Disposable} = require 'atom'
{$, ScrollView} = require 'atom-space-pen-views'
{BaseView} = require '../base-view'
module.exports =
  class WelcomeView extends ScrollView
    @content: ->
      @div class:"welcome", =>
        @raw "<script>
    (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
    (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
    m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
    })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

    ga('create', 'UA-84548828-2', 'auto');
    ga('send', 'pageview');

  </script>"
        @div class:"container", =>
          @header class:"welcome", =>
            @a href:"pros.cs.purdue.edu", =>
              @img src:"http://pros.cs.purdue.edu/img/pros-tux.png", alt:"PROS website"
              @h1 class:"title", -> 'Open Source C Development for the VEX Cortex'
          @section class:"panel", =>
            @p 'For help, please visit:'
            @ul =>
              @li => @raw '<a href:"pros.cs.purdue.edu/getting-started">' +
              'This page</a> for a guide to getting started with PROS for Atom.'
              @li => @raw 'The <a href:"pros.cs.purdue.edu/tutorials">' +
              'PROS tutorial page</a> to learn about using everything from analog' +
              'sensors to tasks and multithreading in PROS.'
              @li => @raw 'The <a href:"pros.cs.purdue.edu/api">' +
              'PROS API documentation</a> for the API reference.'
          @footer class:"footer", =>
            @raw '<a href:"pros.cs.purdue.edu">pros.cs.purdue.edu</a>'
            '<span class:"text-subtle">x</span>'
            '<a href:"github.com/purduesigbots" class:"icon icon-octoface"></a>'

    @deserialize: (options={}) ->
      new WelcomeView(options)

    serialize: ->
      deserializer: @constructor.name
      uri: @getURI()

    getURI: ->
      @uri

    getTitle: ->
      "Welcome"
