fs = require 'fs-plus'
path = require 'path'

module.exports =
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
