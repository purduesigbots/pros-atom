/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const {CompositeDisposable} = require('atom');
const config = require('./config');
const commandExists = require('command-exists');
const fs = require('fs');
const linthelp = require('atom-linter');
const path = require('path');
const {execute} = require('./proscli');
const utils = require('./utils');

let subscriptions = null;
const grammars = ['C', 'C++'];

module.exports = {
    messages: {},
    linter: undefined,
    registry: undefined,

    activate() {
        if (subscriptions != null) {
            subscriptions.dispose();
        }
        subscriptions = new CompositeDisposable;
        if (module.exports.registry) { return module.exports.consumeLinter(module.exports.registry); }
    },


    deactivate() {
        return (subscriptions != null ? subscriptions.dispose() : undefined);
    },

    getValidGrammar(editor) {
        const grammar_name = editor.getGrammar().name;
        if (grammar_name === 'C') {
            return 'C';
        } else if (grammar_name.indexOf('C++' >= 0)) {
            return 'C++';
        } else {
            return undefined;
        }
    },

    lint(editor, lintable_file, real_file) {
        const cwd = utils.findRoot(atom.workspace.getActiveTextEditor().getPath());

        const settings = config.settings(real_file);

        let command = process.env['PROS_TOOLCHAIN'] ?
            path.join(process.env['PROS_TOOLCHAIN'], 'bin', 'arm-none-eabi-g++')
            : 'arm-none-eabi-g++';
        if (navigator.platform === 'Win32') {
            command += '.exe';
        }

        return commandExists(command, (err, commandDoesExist) => {
            if (err) {
                atom.notifications.addError('pros: Error trying to find command',
                    {
                        detail: `Error from command-exists: ${err}`
                    });
            } else if (commandDoesExist || fs.statSync(command).isFile()) {
                let needle;
                let args = [];
                let grammar_type = this.getValidGrammar(editor);
                const flags = (() => {
                    if (grammar_type === 'C++') {
                        return settings.lint.default_Cpp_flags;
                    } else if (grammar_type === 'C') {
                        return settings.lint.default_C_flags;
                    }
                })();
                args = args.concat(flags.split(' '));
                if (settings.lint.error_limit >= 0) {
                    args.push(`-fmax-errors=${settings.lint.error_limit}`);
                }
                for (let include of Array.from(settings.include_paths)) {
                    args.push(`-I${path.join(cwd, include)}`);
                }
                if (settings.lint.suppress_warnings) { args.push('-w'); }
                args.push(lintable_file);
                if ((needle = path.extname(editor.getPath()).toLowerCase(), ['.h' ,'.hpp'].includes(needle))) {
                    args.push('-fsyntax-only');
                } else {
                    const temp = (require('tempfile'))(path.extname(editor.getPath()));
                    args.push(`-o ${temp}`);
                }
                args = args.filter(Boolean);
                return execute({
                    cmd: [command, ...Array.from(args)],
                    includeStdErr: true,
                    cb(c, o, e) {
                        const regex = '(?<file>.+):(?<line>\\d+):(?<col>\\d+):\\s*\\w*\\s*' +
              '(?<type>(error|warning|note)):\\s*(?<message>.*)';
                        const msgs = linthelp.parse(o, regex);
                        msgs.filter(entry => entry.filePath === lintable_file)
                            .forEach(entry => entry.filePath = real_file);
                        module.exports.messages[real_file] = msgs;
                        return __guardMethod__(module.exports.linter, 'setMessages', o1 => o1.setMessages(msgs));
                    }
                });
            } else {
                return atom.notifications.addError('pros: Error trying to find command',
                    {
                        detail: `Couldn't find ${command} in environment`
                    });
            }
        });
    },

    lintOnSave() {
        let needle;
        const editor = atom.workspace.getActiveTextEditor();
        if (!editor || (needle = editor.getGrammar().name, !Array.from(grammars).includes(needle))) { return; }
        return module.exports.lint(editor, editor.getPath(), editor.getPath());
    },

    lintOnTheFly() {
        let needle;
        const editor = atom.workspace.getActiveTextEditor();
        if ((editor == null) || (needle = editor.getGrammar().name, !Array.from(grammars).includes(needle))) { return; }
        if (!config.settings().lint.on_the_fly) { return; }
        const temp = (require('tempfile'))(path.extname(editor.getPath()));
        return (require('fs-extra')).outputFile(temp, editor.getText(), () => module.exports.lint(editor, temp, editor.getPath()));
    },

    consumeLinter(registry) {
        module.exports.registry = registry;
        if (subscriptions != null) {
            subscriptions.dispose();
        }
        subscriptions = new CompositeDisposable;
        module.exports.linter = registry.register({name: 'PROS GCC Linter'});
        subscriptions.add(module.exports.linter);
        return atom.workspace.observeTextEditors(function(editor) {
            subscriptions.add(editor.onDidSave(module.exports.lintOnSave));
            // TODO: onDidStopChanging is a little to agressive with updates
            return subscriptions.add(editor.onDidStopChanging(module.exports.lintOnTheFly));
        });
    }
};

function __guardMethod__(obj, methodName, transform) {
    if (typeof obj !== 'undefined' && obj !== null && typeof obj[methodName] === 'function') {
        return transform(obj, methodName);
    } else {
        return undefined;
    }
}
