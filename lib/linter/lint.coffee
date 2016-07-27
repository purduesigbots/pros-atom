# This linter is based on the linter-gcc Atom package,
# modified to work with the PROS project management
# ecosystem and to use its assumptions... also ported to coffeescript

# Portions of this file are duplicated under the following license:
# Copyright (c) 2015 Husam Hebaishi
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

{CompositeDisposable} = require 'atom'
utility = require './utility'

module.exports =
  messages: {}
  linter_gcc: undefined

  temp_file: {
    'C++': require('tempfile')('.cpp')
    'C': require('tempfile')('.c')
  }

  activate: () =>
    @subscriptions = new CompositeDisposable
    @time_last_lint = new Date().getTime()
    @lint_warning = false

  consumeLinter: (registry) =>
    @linter_gcc = registry.register { name: 'GCC' }

    subs = @subscriptions


    lint = (editor, linted_file, real_file) =>
      helpers = require 'atom-linter'
      # good lord
      regex = "(?<file>.+):(?<line>\\d+):(?<col>\\d+):\\s*\\w*\\s*" +
        "(?<type>error|warning|note)):\\s*(?<message>.*)"
      command = utility.buildCommand editor, linted_file
      console.log command
      return helpers.exec(command.binary, command.args, { stream: 'stderr' }) \
        .then (output) =>
          console.log output
          msgs = helpers.parse output, regex
          msgs.filter((entry) -> entry.filePath in @temp_file) \
            .forEach (entry) -> entry.filePath = real_file
          if msgs.length == 0 && output.indexOf('error') == -1
            msgs = [{
              type: 'error'
              text: output
              filePath: real_file
            }]
          module.exports.messages[real_file] = msgs
          if typeof @linter_gcc != 'undefined'
            @linter_gcc.setMessages JSON.parse JSON.stringify \
              require('./utility').flattenHash module.exports.messages
          return msgs

    lintOnTheFly = () =>
      editor = utility.getValidEditor atom.workspace.getActiveTextEditor()
      if !editor then return
      if !atom.config.get 'purdueros-atom.lint_on_the_fly' then return
      if lint_waiting then return
      lint_waiting = true
      interval = atom.config.get 'purdueros-atom.lint_on_the_fly_interval'
      time_now = new Date().getTime()
      timeout = interval - (time_now - time_last_lint)
      setTimeout((() =>
        time_last_lint = new Date().getTime()
        lint_waiting = false
        grammar_type = utility.grammarType editor.getGrammar().name
        filename = String @temp_file[grammar_type]
        require('fs-extra').outputFileSync filename, editor.getPath()
        lint editor, filename, editor.getPath()
        ),
        timeout)


    lintOnSave = () ->
      editor = utility.getValidEditor atom.workspace.getActiveTextEditor()
      if !editor then return
      if atom.config.get('purdueros-atom.lint_on_the_fly') then return
      lint editor, editor.getPath(), editor.getPath()

    cleanupMessages = () ->
      editor_hash = {}
      atom.workspace.getTextEditors().forEach (entry) ->
        try path = entry.getPath() catch err then err
        editor_hash[entry.getPath()] = 1
      @messages.filter((file) -> !editor_hash.hasOwnProperty file) \
        .forEach (file) -> delete @messages[file]
      @linter_gcc.setMessages JSON.parse JSON.stringify \
        require('./utility').flattenHash @messages

    subs.add @linter_gcc
    atom.workspace.observeTextEditors (editor) ->
      subs.add editor.onDidSave lintOnSave
      subs.add editor.onDidStopChanging lintOnTheFly
      subs.add editor.onDidDestroy cleanupMessages
