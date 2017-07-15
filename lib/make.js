/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const fs = require('fs');
const path = require('path');
// const os = require('os');
// const cp = require('child_process');
const voucher = require('voucher');
const {EventEmitter} = require('events');
const config = require('./config');

module.exports = {
    provideBuilder() {
        let MakeBuildProvider;
        const gccErrorMatch = '(?<file>([A-Za-z]:[\\/])?[^:\\n]+):(?<line>\\d+):' +
      '(?<col>\\d+):\\s*(fatal error|error|warning):\\s*(?<message>.+)';
        const ocamlErrorMatch = '(?<file>[\\/0-9a-zA-Z\\._\\-]+)", line (?<line>\\d+), ' +
      'characters (?<col>\\d+)-(?<col_end>\\d+):\\n(?<message>.+)';
        const errorMatch = [ gccErrorMatch, ocamlErrorMatch ];

        return (MakeBuildProvider = class MakeBuildProvider extends EventEmitter {
            constructor(cwd) {
                super(...arguments);
                this.cwd = cwd;
                atom.config.observe('build-make.jobs', () => this.emit('refresh'));
            }

            getNiceName() { return 'GNU Make for PROS'; }

            isEligible() {
                if (atom.config.get('pros.enable')) {
                    this.files = [ 'Makefile', 'GNUmakefile', 'makefile' ]
                        .map(f => path.join(this.cwd, f))
                        .filter(fs.existsSync);
                    return this.files.length > 0;
                } else { return false; }
            }

            settings() {
                const args = [ (`-j${config.settings('.').parallel_make_jobs}`) || 1];

                if ((navigator.platform === 'Win32') &&
                     !!process.env['PROS_TOOLCHAIN'] &&
                     !Array.from(process.env['PATH']).includes(process.env['PROS_TOOLCHAIN'])) {
                    process.env['PATH'] =
                      path.join(process.env['PROS_TOOLCHAIN'], 'bin') + ';' + process.env['PATH'];
                }

                // makeCmd = path.join process.env['PROS_TOOLCHAIN'], 'bin', 'make'
                // else
                const makeCmd = 'make';

                const defaultTarget = {
                    exec: makeCmd,
                    name: 'PROS GNU Make: default',
                    args,
                    sh: false,
                    functionMatch(output) {
                        console.log(output);
                        const match = /((.+):(\d+):(\d+): (note|error|warning):\s*(.+))/gm.exec(output);
                        console.log(match);
                        return [];
                    }
                    // errorMatch: errorMatch
                };

                const promise = atom.config.get('build-make.useMake')
                    ? voucher(exec, makeCmd + ' -prRn', { cwd: this.cwd })
                    : voucher(fs.readFile, this.files[0]);

                return promise.then(output =>
                    [defaultTarget].concat(output.toString('utf8')
                        .split(/[\r\n]{1,2}/)
                        .filter(line => /^[a-zA-Z0-9][^$#/\t=]*:([^=]|$)/.test(line))
                        .map(targetLine => targetLine.split(':').shift())
                        .map(target => ({
                            exec: makeCmd,
                            args: args.concat([target]),
                            name: `PROS GNU Make ${target}`,
                            sh: false,
                            errorMatch
                        }) ))).catch(e => defaultTarget);
            }
        });
    }
};
