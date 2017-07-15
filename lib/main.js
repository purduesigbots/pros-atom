/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const {CompositeDisposable} = require('atom');
// const {Disposable} = require('atom');
// const fs = require('fs');
const path = require('path');
const cli = require('./proscli');
const GA = require('./ga');
const {provideBuilder} = require('./make');
const lint = require('./lint');
const config = require('./config');
const universalConfig = require('./universal-config');
const autocomplete = require('./autocomplete/autocomplete-clang');
const buttons = require('./buttons');
const Status = require('./views/statusbar');
// const utils = require('./utils');

let WelcomeView = null;
let ConductorView = null;
// const AddLibraryModal = null;

const welcomeUri = 'pros://welcome';
const conductorUri = 'pros://conductor';
const conductorRegex = /conductor\/(.+)/i;
// const addLibraryUri = 'pros://addlib';
// const addLibraryRegex = /addlib\/(.+)/i;

let toolBar = null;
let getToolBar = null;

module.exports = {
    provideBuilder,

    activate() {
        this.subscriptions = new CompositeDisposable;
        require('atom-package-deps').install('pros').then(() => {
            // Generate a new client ID if needed
            // atom.config.get 'pros.googleAnalytics.enabled' and\
            // Begin client session
            let grammarSubscription;
            GA.startSession();
            // Watch config to make sure we start or end sessions as needed
            atom.config.onDidChange('pros.googleAnalytics.enabled', function() {
                if (atom.config.get('pros.googleAnalytics.enabled') &&
           (atom.config.get('core.telemetryConsent') === 'limited')) {
                    GA.startSession();
                } else {
                    atom.config.set('pros.googleAnalytics.cid', '');
                    GA.sendData({sessionControl: 'end'});
                }
            });

            atom.config.onDidChange('core.telemetryConsent', function() {
                if (atom.config.get('core.telemetryConsent') === 'no') {
                    GA.sendData({sessionControl: 'end'});
                }
            });

            if (config.settings('').override_beautify_provider) {
                atom.config.set('atom-beautify.c.default_beautifier', 'clang-format');
            }

            if (atom.config.get('pros.enable')) {
                lint.activate();
                autocomplete.activate();
            }

            atom.commands.add('atom-workspace', {'PROS:New-Project': () => new (require('./views/new-project'))});
            atom.commands.add('atom-workspace', {'PROS:Upgrade-Project': () => {
                const currentProject = atom.project.relativizePath(__guard__(atom.workspace.getActiveTextEditor(), x => x.getPath()));
                if (currentProject[0]) {
                    return new ( require('./views/upgrade-project'))({dir: currentProject[0]});
                } else {
                    return new (require('./views/upgrade-project'));
                }
            }
            }
            );
            atom.commands.add('atom-workspace', {'PROS:Register-Project': () => new (require('./views/register-project'))});
            atom.commands.add('atom-workspace', {'PROS:Upload-Project': () => this.uploadProject()});
            atom.commands.add('atom-workspace', {'PROS:Toggle-Terminal': () => this.toggleTerminal()});
            atom.commands.add('atom-workspace', {'PROS:Show-Welcome': () => atom.workspace.open(welcomeUri)});
            atom.commands.add('atom-workspace', {'PROS:Toggle-PROS': () => atom.config.set('pros.enable', !atom.config.get('pros.enable'))});
            atom.commands.add('atom-workspace', {
                'PROS:Open-Conductor': () => {
                    const currentProject = atom.project.relativizePath(__guard__(atom.workspace.getActiveTextEditor(), x => x.getPath()));
                    if (currentProject[0]) {
                        atom.workspace.open(`${conductorUri}/${currentProject[0]}`);
                    } else {
                        atom.workspace.open(conductorUri);
                    }
                }
            }
            );
            atom.commands.add('atom-workspace', {
                'PROS:Add-Library': () => new (require('./views/add-library'))({path: __guard__(atom.project.getPaths(), x => x[0])})
            }
            );

            this.subscriptions.add(atom.workspace.addOpener(uri => {
                if (uri === welcomeUri) {
                    return WelcomeView != null ? WelcomeView : (WelcomeView = new (require('./views/welcome')));
                }
            })
            );

            this.subscriptions.add(atom.workspace.addOpener(uri => {
                if (uri.startsWith(conductorUri)) {
                    let match;
                    if (ConductorView == null) { ConductorView = new (require('./views/conductor'))({conductorUri}); }
                    if ((match = conductorRegex.exec(uri))) {
                        ConductorView.updateAvailableProjects();
                        ConductorView.updateSelectedPath(match[1]);
                    }
                    return ConductorView;
                }
            })
            );

            if (atom.config.get('pros.welcome.enabled')) {
                atom.workspace.open(welcomeUri);
            }

            atom.config.onDidChange('pros.enable', ({newValue, oldValue}) => {
                if (newValue === oldValue) { return; }
                atom.commands.dispatch(atom.views.getView(atom.workspace.getActivePane()), 'build:refresh-targets');
                if (newValue) { // PROS is now enabled
                    lint.activate();
                    autocomplete.activate();
                    if (getToolBar) { return this.consumeToolbar(getToolBar); }
                } else { // PROS is now disabled
                    lint.deactivate();
                    autocomplete.deactivate();
                    return (toolBar != null ? toolBar.removeItems() : undefined);
                }
            });
            this.PROSstatus = true;

            cli.execute({
                cmd: cli.prosConduct('first-run', '--no-force', '--use-defaults'),
                cb(c, o, e) { if (o) { console.log(o); } }
            });

            cli.checkCli({minVersion: atom.packages.getLoadedPackage('pros').metadata.cli_pros.version, cb(c, o) {
                if (c !== 0) { return atom.workspace.open('pros://welcome'); }
            }
            });

            grammarSubscription = atom.grammars.onDidAddGrammar(grammar => {
                if (grammar.scopeName === 'source.json') {
                    grammarSubscription.dispose();
                    grammar.fileTypes.push('pros');
                    process.nextTick(() => {
                        const result = [];
                        for (let e of Array.from(atom.workspace.getTextEditors())) {
                            atom.workspace.getActiveTextEditor();
                            if (Boolean(e.getPath()) && (path.extname(e.getPath()) === '.pros')) {
                                result.push(e.setGrammar(grammar));
                            } else {
                                result.push(undefined);
                            }
                        }
                        return result;
                    });
                }
            });
        });
    },

    deactivate() {
        if (this.statusBarTile != null) {
            this.statusBarTile.destroy();
        }
        this.statusBarTile = null;
        // End client session
        if (atom.config.get('pros.googleAnalytics.enabled') &&
       (atom.config.get('core.telemetryConsent') === 'limited')) {
            GA.sendData({sessionControl: 'end'});
        }
    },

    consumeLinter: lint.consumeLinter,

    consumeRunInTerminal(service) {
        return cli.consumeTerminalService(service);
    },

    uploadProject() {
        if (atom.project.getPaths().length > 0) {
            return cli.executeInTerminal({cmd: [
                'pros', 'flash', '-f', '"' +
        (atom.project.relativizePath(__guard__(atom.workspace.getActiveTextEditor(), x => x.getPath()))[0] ||
          atom.project.getPaths()[0]) + '"'
            ]});
        }
    },

    toggleTerminal() { return cli.executeInTerminal({cmd: ['pros', 'terminal']}); },

    consumeToolbar(toolBarRegister) {
        getToolBar = toolBarRegister;
        toolBar = getToolBar('pros');
        if (atom.config.get('pros.enable')) {
            buttons.addButtons(toolBar);
        }
        toolBar.onDidDestroy(() => toolBar = null);
    },

    autocompleteProvider() { return autocomplete.provide(); },

    consumeStatusBar(statusbar) {
        Status.attach(statusbar);
    },

    deserializeConductorView(data) { return ConductorView != null ? ConductorView : (ConductorView = new (require('./views/conductor'))(data)); },
    deserializeWelcomeView(data) { return WelcomeView != null ? WelcomeView : (WelcomeView = new (require('./views/welcome'))(data)); },

    config: universalConfig.filterConfig(config.config, 'atom')
};

function __guard__(value, transform) {
    return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
