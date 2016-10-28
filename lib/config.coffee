path = require 'path'
fs = require 'fs'
{loadConfig} = require './universal-config'

module.exports =

  FILENAME: 'pros-atom.json'
  niceName: "pros-atom configuration (#{@FILENAME})"

  settings: (file_path = atom.workspace.getActiveTextEditor().getPath()) ->
    loadConfig @config, null, 'pros',
      project:
        filename: 'atom-project.pros'
      directory:
        filename: 'atom-project.pros'
        recurseTimes: atom.config.get 'pros-atom.max_scan_iterations'

  # settings: (file_path = atom.workspace.getActiveTextEditor().getPath()) ->
  #   MAX_ITERS = atom.config.get 'pros-atom.max_scan_iterations'
  #
  #   directory_settings = path.join path.dirname(file_path), @FILENAME
  #   config_file = ''
  #
  #   if fs.existsSync directory_settings
  #     config_file = directory_settings
  #   if config_file == '' && atom.project.getPaths()[0] != undefined
  #     current_path = atom.project.getPaths()[0]
  #     for [1...atom.config.get 'pros.max_scan_iterations']
  #       if fs.existsSync path.join current_path, @FILENAME
  #         config_file = path.join current_path, @FILENAME
  #         break
  #       current_path = path.join current_path, '..'
  #   data = {}
  #   if config_file != ''
  #     delete require.cache[config_file]
  #     data = require config_file
  #
  #   valOrDefault = (obj, property, default_key) ->
  #     if !obj.hasOwnProperty property then atom.config.get default_key
  #     else obj[property]
  #
  #   result = {
  #     lintDefaultCFlags: data.lintDefaultCFlags or
  #       atom.config.get 'pros.lint_default_C_flags'
  #     lintDefaultCppFlags: data.lintDefaultCppFlags or
  #       atom.config.get 'pros.lint_default_Cpp_flags'
  #     lintErrorLimit: data.lintErrorLimit or
  #       atom.config.get 'pros.lint_error_limit'
  #     lintIncludePaths: data.lintIncludePaths or
  #       atom.config.get 'pros.lint_include_paths'
  #     lintSuppressWarnings: data.lintSuppressWarnings or
  #       atom.config.get 'pros.lint_suppress_warnings'
  #   }
  #   return result

  config:
    override_beautify_provider:
      type: 'boolean'
      default: true
      scope: ['atom']
    parallel_make_jobs:
      type: 'integer'
      default: 2
      minimum: 1
      scope: ['atom']
    max_scan_iterations:
      type: 'integer'
      default: 10
      minimum: 2
    include_paths:
      type: 'array'
      default: ['./include']
      items:
        type: 'string'
    autocomplete:
      type: 'object'
      properties:
        flags:
          type: 'array'
          default: []
          items:
            type: 'string'
        includeDocumentation:
          type: 'boolean'
          default: true
        includeNonDoxygenCommentsAsDocumentation:
          type: 'boolean'
          default: 'true'
    googleAnalytics:
      title: 'Google Analytics'
      type: 'object'
      properties:
        enabled:
          title: 'Enable Google Analytics'
          description: \
          'If set to \'true,\' you help us to understand and better cater to our'+\
          'user-base by sending us information about the size, relative geograph'+\
          'ic area, and general activities of the people using PROS.'
          type: 'boolean'
          default: true
        cid:
          title: 'Google Analytics client ID'
          description: \
          'Used when making requests to the GA API.
          Please do not change this value unless you have \'enabled\' set to \'false\''
          type: 'string'
          default: ''
    welcome:
      title: 'Welcome Page'
      type: 'object'
      properties:
        enabled:
          title: 'Show on startup'
          type: 'boolean'
          default: true
    lint:
      type: 'object'
      properties:
        default_C_flags:
          type: 'string'
          default: '-Wall'
        default_Cpp_flags:
          type: 'string'
          default: '-Wall -std=c++11'
        error_limit:
          type: 'integer'
          default: 15
        suppress_warnings:
          type: 'boolean'
          default: false
        on_the_fly:
          type: 'boolean'
          default: true
        on_the_fly_interval:
          type: 'integer'
          default: 250
          minimum: 1
