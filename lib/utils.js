/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * DS208: Avoid top-level this
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const fs = require('fs-plus');
const path = require('path');
const cp = require('child_process');
const async = require('async');
this.cliVersion = '';
this.pkgVersion = '';

module.exports = {
  cliVersion: () => this.cliVersion,

  pkgVersion: () => this.pkgVersion,

  findRoot(_path, n) {
    if (n == null) { n = 10; }
    const originalPath = _path;
    _path = fs.absolute(_path);
    for (let x = 1, end = n; x < end; x++) {
      if (_path && fs.existsSync(_path)) {
        if (fs.isDirectorySync(_path) && fs.existsSync(_path + "/project.pros")) {
          return _path;
        } else {
          _path = fs.absolute(_path + '/..');
        }
      } else {
        return atom.project.relativizePath(originalPath)[0] || originalPath;
      }
    }
    return atom.project.relativizePath(originalPath)[0] || originalPath;
  },

  packageVersion: cb0 => {
    const cb = (err, stdout, stderr) => {
      if (err) {
        return console.log(`error getting package version: ${error}`);
      } else {
        return this.pkgVersion = stdout.replace('pros@', '');
      }
    };
        // cb0 @pkgVersion

    if (navigator.platform === 'Win32') {
      return cp.exec('apm list -d -i -l -p --bare | find /i "pros"', cb);
    } else {
      return cp.exec('apm list -d -i -l -p --bare | grep "pros"', cb);
    }
  },

    // cb0 @pkgVersion

  prosVersion: cb0 => {
    return cp.exec('pros --version', (err, stdout, stderr) => {
      if (err) {
        return console.log(`error getting package version: ${error}`);
      } else {
        return this.cliVersion = stdout.replace('pros, version ', '');
      }
    });
  },

    // cb0 @cliVersion

  findOpenPROSProjectsSync() {
    const results = [];
    var traversal = dir =>
      fs.traverseTreeSync(dir,
      (function(file) {
        if (path.basename(file) === 'project.pros') {
          return results.push(path.dirname(file));
        }
      }),
      (function(d) {
        if (!path.basename(d).startsWith('.')) {
          try { return traversal(d); }
          catch (e) {}
        }
    } )
      )
    ;
    for (let project of Array.from(atom.project.getPaths())) { traversal(project); }
    return results;
  }
};
