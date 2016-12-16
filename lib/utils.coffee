fs = require 'fs-plus'
path = require 'path'
cp = require 'child_process'
async = require 'async'
@cliVersion = ''
@pkgVersion = ''

module.exports =
  cliVersion: =>
    return @cliVersion

  pkgVersion: =>
    console.log "func: #{@pkgVersion}"
    return @pkgVersion

  findRoot: (_path, n = 10) ->
    originalPath = _path
    _path = fs.absolute _path
    for x in [1...n] by 1
      if _path and fs.existsSync(_path)
        if fs.isDirectorySync(_path) and fs.existsSync(_path + "/project.pros")
          return _path
        else
          _path = fs.absolute _path + '/..'
      else
        return atom.project.relativizePath(originalPath)[0] or originalPath
    return atom.project.relativizePath(originalPath)[0] or originalPath

  packageVersion: (cb0) =>
    cb = (err, stdout, stderr) =>
      if err
        console.log "error getting package version: #{error}"
      else
        @pkgVersion = stdout.replace 'pros@', ''
        # cb0 @pkgVersion

    if navigator.platform is 'Win32'
      cp.exec 'apm list -d -i -l -p --bare | find /i "pros"', cb
    else
      cp.exec 'apm list -d -i -l -p --bare | grep "pros"', cb

    # cb0 @pkgVersion

  prosVersion: (cb0) =>
    cp.exec 'pros --version', (err, stdout, stderr) =>
      if err
        console.log "error getting package version: #{error}"
      else
        @cliVersion = stdout.replace 'pros, version ', ''

    # cb0 @cliVersion

  findOpenPROSProjectsSync: ->
    results = []
    traversal = (dir) ->
      fs.traverseTreeSync dir,
      ((file) ->
        if path.basename(file) == 'project.pros'
          results.push path.dirname file
      ),
      ((d) ->)
    traversal project for project in atom.project.getPaths()
    return results
