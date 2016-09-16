fs = require 'fs'
path = require 'path'
os = require 'os'
cp = require 'child_process'
voucher = require 'voucher'
{EventEmitter} = require 'events'
config = require './config'

module.exports =
  provideBuilder: ->
    gccErrorMatch = '(?<file>([A-Za-z]:[\\/])?[^:\\n]+):(?<line>\\d+):' +
      '(?<col>\\d+):\\s*(fatal error|error|warning):\\s*(?<message>.+)'
    ocamlErrorMatch = '(?<file>[\\/0-9a-zA-Z\\._\\-]+)", line (?<line>\\d+), ' +
      'characters (?<col>\\d+)-(?<col_end>\\d+):\\n(?<message>.+)'
    errorMatch = [ gccErrorMatch, ocamlErrorMatch ]

    return class MakeBuildProvider extends EventEmitter
      constructor: (cwd) ->
        super
        @cwd = cwd
        atom.config.observe 'build-make.jobs', => @emit 'refresh'

      getNiceName: () -> return 'GNU Make for PROS'

      isEligible: () ->
        @files = [ 'Makefile', 'GNUmakefile', 'makefile' ]
          .map((f) => path.join @cwd, f)
          .filter fs.existsSync
        return @files.length > 0

      settings: () ->
        args = [ '-j' + config.settings('.').parallel_make_jobs or 2]

        if navigator.platform == 'Win32' and !!process.env['PROS_TOOLCHAIN'] and \
           process.env['PROS_TOOLCHAIN'] not in process.env['PATH']
          process.env['PATH'] = path.join(process.env['PROS_TOOLCHAIN'], 'bin') + ';' \
            + process.env['PATH']

          # makeCmd = path.join process.env['PROS_TOOLCHAIN'], 'bin', 'make'
        # else
        makeCmd = 'make'

        defaultTarget = {
          exec: makeCmd,
          name: 'PROS GNU Make: default',
          args: args,
          sh: false,
          functionMatch: (output) ->
            console.log output
            match = /((.+):(\d+):(\d+): (note|error|warning):\s*(.+))/gm.exec output
            console.log match
            return []
          # errorMatch: errorMatch
        }

        promise = if atom.config.get 'build-make.useMake' \
          then voucher exec, makeCmd + ' -prRn', { cwd: @cwd } \
          else voucher fs.readFile, @files[0]

        return promise.then((output) ->
          return [defaultTarget].concat(output.toString('utf8')
            .split(/[\r\n]{1,2}/)
            .filter (line) -> /^[a-zA-Z0-9][^$#\/\t=]*:([^=]|$)/.test line
            .map (targetLine) -> targetLine.split(':').shift()
            .map (target) -> {
              exec: makeCmd,
              args: args.concat([target]),
              name: 'PROS GNU Make ' + target,
              sh: false,
              errorMatch: errorMatch
            })).catch (e) -> defaultTarget
