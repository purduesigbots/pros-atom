/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__
 * DS201: Simplify complex destructure assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const {$} = require('atom-space-pen-views');
const {Disposable} = require('atom');
const cp = require('child_process');
const semver = require('semver');
const statusbar = require('./views/statusbar');
const {EOL} = require('os');
// const brand = require('./views/brand');
// const {setTimeout} = require('timers');

let terminalService = null;
let currentTerminal = null;
let cliVer = null;

const createHtmlSafeString = str => { // unnecessary fat arrow in coffeescript doesn't mean we can't use it here
    const temp = document.createElement('div');
    temp.appendChild(document.createTextNode(str));
    return temp.innerHTML;
};

module.exports = {
    prosConduct(...options) { return ['pros', 'conduct', ...Array.from(options)]; },
    execute(params) {
        var cmd, cb, includeStdErr, onstderr, onstdout, nosb;
        ({cmd, cb, includeStdErr, onstderr, onstdout, nosb} = params);
        if (!nosb) { statusbar.working(); }
        let outBuf = '';
        let errBuf = '';
        // cmd = cmd.join ' '
        const { env } = process;
        if (atom.config.get('pros.locale') !== 'inherit') {
            env['LC_ALL'] = atom.config.get('pros.locale');
            env['LANG'] = atom.config.get('pros.locale');
        }
        const proc = cp.spawn(cmd[0], cmd.slice(1), {
            env,
            cwd: (typeof params !== 'undefined' && params !== null ? params.cwd : undefined)
        }
        );
        proc.on('error', err => console.log(err));
        proc.stderr.on('data', function(data) {
            if (includeStdErr) {
                outBuf += data;
            }
            errBuf += data;
            typeof onstderr === 'function' ? onstderr(data) : undefined;
        });
        proc.stdout.on('data', function(data) {
            outBuf += data;
            typeof onstdout === 'function' ? onstdout(data) : undefined;
        });
        proc.on('close', function(c, s) {
            if (!nosb) { statusbar.stop(); }
            // console.log errBuf if errBuf
            cb(c, outBuf, errBuf);
        });
        return proc;
    },

    checkCli(...args) {
        const obj = args[0],
            { minVersion,
                cb } = obj,
            val = obj.fmt,
            fmt = val != null ? val : 'text',
            val1 = obj.force,
            force = val1 != null ? val1 : false,
            val2 = obj.nosb,
            nosb = val2 != null ? val2 : false,
            val3 = obj.eol,
            eol = val3 != null ? val3 : EOL;
        const mapResponse = function(fmt, obj) {
            let div;
            if (fmt === 'raw') { return obj; }
            const {code, extra} = obj;
            switch (code) {
            case 1:
                switch (fmt) {
                case 'html':
                    div = $('<div>PROS CLI is out of date. </div>');
                    div.append(`<span class='status-modified'>(${extra})</span> `);
                    div.append('Visit ');
                    div.append('<a href=\'http://pros.cs.purdue.edu/upgrading\'>pros.cs.purdue.edu/upgrading</a>');
                    div.append(' to learn more.');
                    return div;
                default: return `PROS CLI is out of date. (${extra}).`;
                }
            case 2:
                switch (fmt) {
                case 'html': return 'PROS CLI was not found on your PATH.';
                default: return 'PROS CLI was not found on your PATH.';
                }
            case 3:
                switch (fmt) {
                case 'html':
                    div = $('<div style=\'text-align: left; white-space: pre-line\'></div>');
                    div.text(`PROS CLI is improperly configured.${eol}${extra}`);
                    return div;
                default: return 'PROS CLI is improperly configured.';
                }
            default: return obj.version != null ? obj.version : obj.extra;
            }
        };
        const respond = function(obj){
            if (statusbar.tooltip != null) {
                statusbar.tooltip.dispose();
            }
            statusbar.button.removeClass('has-update');
            if (obj.code === 1) {
                statusbar.button.addClass('has-update');
            }
            statusbar.updateTooltip();
            return cb(obj.code, mapResponse(fmt, obj));
        };

        if ((cliVer !== null) && !force) { respond(cliVer); }
        const which = ['which', 'pros'];
        if (navigator.platform === 'Win32') { which[0] = 'where'; }
        return this.execute({cmd: which, nosb, cb: (c, o) => {
            if (c !== 0) {
                // console.log o
                cliVer = {code: 2};
                respond(cliVer);
                return;
            }
            return this.execute({cmd: ['pros', '--version'], nosb, cb: (c, o, e) => {
                if (c !== 0) {
                    // console.log {c, o, e}
                    cliVer = {code: 3, extra: `STDOUT:${eol}${o}${eol}${eol}ERR:${eol}${e}`};
                    respond(cliVer);
                    return;
                }
                let version = __guard__(/pros, version \b(v?(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)(?:-[\da-z\-]+(?:\.[\da-z\-]+)*)?(?:\+[\da-z\-]+(?:\.[\da-z\-]+)*)?)\b/.exec(o), x => x[1]);
                if (version === undefined) {
                    // try again one more time, just in case
                    this.execute({cmd: ['pros', '--version'], nosb, cb(c, o) {
                        if (c !== 0) {
                            // console.log o
                            cliVer = {code: 3, extra: `STDOUT:${eol}${o}${eol}${eol}ERR:${eol}${e}`};
                            respond(cliVer);
                            return;
                        }
                        // coffeelint: disable=max_line_length
                        version = __guard__(/pros, version \b(v?(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)(?:-[\da-z\-]+(?:\.[\da-z\-]+)*)?(?:\+[\da-z\-]+(?:\.[\da-z\-]+)*)?)\b/.exec(o), x1 => x1[1]);
                        // coffeelint: enable=max_line_length
                        if (!version || semver.lt(version, minVersion)) {
                            // console.log o
                            cliVer = {code: 1, extra: `v${version} does not meet v${minVersion}`, version};
                            respond(cliVer);
                            return;
                        }
                        cliVer = {code: 0, extra: version};
                        return respond(cliVer);
                    }
                    });
                } else if (!version || semver.lt(version, minVersion)) {
                    // console.log o
                    cliVer = {code: 1, extra: `v${version} does not meet v${minVersion}`, version};
                    respond(cliVer);
                    return;
                }
                cliVer = {code: 0, version};
                return respond(cliVer);
            }
            });
        }
        });
    },

    invUpgrade(callback) {
        return this.execute({cmd: ['pros', 'upgrade', '--machine-output'], cb(c, o, e) {
            if (c !== 0) {
                return atom.notifications.addError('Unable to determine how PROS CLI is installed',
                    {detail: 'You will need to upgrade PROS CLI for your intallation method.'});
            } else {
                const cmd = o.split('\n').filter(Boolean).map(Function.prototype.call, String.prototype.trim);
                if ((navigator.platform === 'Win32') && (cmd.length === 3)) {  // fix for calling upgrader on Windows
                    cmd[1] = '/checknow';
                    cmd[2] = '/reducedgui';
                }
                if (!atom.inDevMode()) {
                    return cp.execFile(cmd[0], cmd.slice(1));
                } else {
                    return console.log(`Running ${cmd.join(' ')}`);
                }
            }
        }
        });
    },

    executeInTerminal({cmd}) {
        const wait = function(ms) {
            const start = new Date().getTime();
            return (() => {
                const result = [];
                for (let num = 0; num < 1e7; num++) {
                    if ((new Date().getTime() - start) > ms) {
                        break;
                    } else {
                        result.push(undefined);
                    }
                }
                return result;
            })();
        };
        if (terminalService) {
            if (currentTerminal) {
                currentTerminal.insertSelection('\x03');
                wait(75); // hard code waits to allow commands to be executed
                currentTerminal.insertSelection(navigator.platform === 'Win32' ? 'cls' : 'clear');
                wait(75);
                currentTerminal.insertSelection(cmd.join(' '));
                currentTerminal.focus();
            } else {
                currentTerminal = terminalService.run([cmd.join(' ')])[0].spacePenView;
                currentTerminal.statusIcon.style.color = '#cca352';
                currentTerminal.statusIcon.updateName('PROS CLI');
                currentTerminal.panel.onDidDestroy(() => currentTerminal = null);
            }
            return currentTerminal;
        } else {
            return null;
        }
    },

    consumeTerminalService(service) {
        if (terminalService) {
            return new Disposable(function() {  });
        }
        terminalService = service;
        return new Disposable(function() { return terminalService; });
    }
};

function __guard__(value, transform) {
    return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
