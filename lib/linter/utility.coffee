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

path = require 'path'
config = require '../config'

module.exports =
  flattenHash: (obj) ->
    arr = []
    for key in obj
      if obj.hasOwnProperty key
        obj[key].forEach arr.push entry
    return arr

  walkSync: (dir, fileList) ->
    fs = fs || require 'fs'
    files = fileList || []
    files.forEach (file) ->
      if fs.statSync(dir + '/' + file).isDirectory()
        fileList.push(dir + '/' + file)
        fileList = @walkSync dir + '/' + file, fileList
    return fileList

  grammarType: (grammar_name) ->
    if grammar_name == 'C' then 'C'
    else if grammar_name.indexOf 'C++' != -1 then 'C++'
    else undefined

  getValidEditor: (editor) ->
    if !editor then return undefined
    grammar = editor.getGrammar().name
    if !@grammarType grammar then return undefined
    return editor

  getCwd: () ->
    cwd = atom.project.getPaths()[0]
    if !cwd
      editor = atom.workspace.getActivePaneItem()
      if editor
        temp_file = editor.buffer.file
        if temp_file
          cwd = temp_file.getParent().getPath()
    if cwd then return cwd else return ''

  getFileDir: () ->
    fileDir = null
    editor = atom.workspace.getActivePaneItem()
    if editor
      temp_file = editor.buffer.file
      if temp_file
        fileDir = temp_file.getParent().getPath()
    return fileDir

  splitStringTrim: (str, delim, expandPaths, itemPrefix) =>
    output = []
    if !str then return output
    str = str.trim()
    if str.length == 0 then return output
    temp_arr = require('split-string')(str, delim)
    temp_arr.forEach (item) =>
      item = item.trim()
      if item.length > 0
        if item.substring(0, 1) == '.' and expandPaths
          item = path.join @getFileDir(), item
        else if item.substring(0, 1) == '-' and expandPaths
          item = item.substring 1, item.length
          item = path.join @getFileDir(), item
        if item.substring(item.length - 2, item.length) == '/*' and expandPaths
          item = item.substring 0, item.length - 2
          list = []
          dir_list = @walkSync(item, list).forEach (item) ->
            item = itemPrefix + item
            output.push item
        item = itemPrefix + item
        output.push item
    return output

  buildCommand: (activeEditor, file) ->
    cwd = @getCwd()
    settings = config.settings()
    if !!process.env['PROS_TOOLCHAIN']
      command = path.join process.env['PROS_TOOLCHAIN'], 'bin', \
        'arm-none-eabi-g++'
    else
      command = 'arm-none-eabi-g++'
    console.log command
    # command = require('shelljs').which command
    # console.log command
    if !command
      atom.notifications.addError 'purdueros: arm-none-eabi-g++ not found', {}
      return
    args = []
    flags = ''
    grammar_type = @grammarType activeEditor.getGrammar().name
    if grammar_type == 'C++'
      flags = settings.lintDefaultCppFlags
    else if grammar_type == 'C'
      flags = settings.lintDefaultCFlags

    args = args.concat @splitStringTrim flags, ' ', false, ''

    if settings.lintErrorLimit >= 0
      args.push "-fmax-errors=#{settings.lintErrorLimit}"
    if settings.lintSuppressWarnings then args.push '-w'

    args = args.concat settings.lintIncludePaths?.forEach (item) -> "-I#{item}"
    args.push file

    console.log 'linter: ' + command + args.join ' '
    return { binary: command, args: args }
