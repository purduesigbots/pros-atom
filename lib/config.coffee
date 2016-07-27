path = require 'path'
fs = require 'fs'

module.exports =
  FILENAME: 'purdueros-atom.json'
  niceName: "purdueros-atom configuration (#{@FILENAME})"

  settings: (file_path = atom.workspace.getActiveTextEditor().getPath()) ->
    MAX_ITERS = atom.config.get 'purdueros-atom.max_scan_iterations'

    directory_settings = path.join path.dirname(file_path), @FILENAME
    config_file = ''

    if fs.existsSync directory_settings
      config_file = directory_settings
    if config_file == '' && atom.project.getPaths()[0] != undefined
      current_path = atom.project.getPaths()[0]
      for [1...atom.config.get 'purdueros.max_scan_iterations']
        if fs.existsSync path.join current_path, @FILENAME
          config_file = path.join current_path, @FILENAME
          break
        current_path = path.join current_path, '..'
    data = {}
    if config_file != ''
      delete require.cache[config_file]
      data = require config_file

    valOrDefault = (obj, property, default_key) ->
      if !obj.hasOwnProperty property then atom.config.get default_key
      else obj[property]

    result = {
      lintDefaultCFlags: data.lintDefaultCFlags or
        atom.config.get 'purdueros.lint_default_C_flags'
      lintDefaultCppFlags: data.lintDefaultCppFlags or
        atom.config.get 'purdueros.lint_default_Cpp_flags'
      lintErrorLimit: data.lintErrorLimit or
        atom.config.get 'purdueros.lint_error_limit'
      lintIncludePaths: data.lintIncludePaths or
        atom.config.get 'purdueros.lint_include_paths'
      lintSuppressWarnings: data.lintSuppressWarnings or
        atom.config.get 'purdueros.lint_suppress_warnings'
    }
    return result

  config:
    parallel_make_jobs:
      type: 'integer'
      default: 2
      minimum: 1
    max_scan_iterations:
      type: 'integer'
      default: 10
      minimum: 2
    lint_default_C_flags:
      type: 'string'
      default: '-Wall'
    lint_default_Cpp_flags:
      type: 'string'
      default: '-Wall -std=c++11'
    lint_error_limit:
      type: 'integer'
      default: 15
    lint_include_paths:
      type: 'array'
      default: ['./include']
      items:
        type: 'string'
    lint_suppress_warnings:
      type: 'boolean'
      default: false
    lint_on_the_fly:
      type: 'boolean'
      default: true
    lint_on_the_fly_interval:
      type: 'integer'
      default: 250
      minimum: 1
