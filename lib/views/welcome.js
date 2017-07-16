/** @babel */
/** @jsx etch.dom */

const brand = require('./brand');
const cli = require('../proscli');
const std = require('./standard');

var {CompositeDisposable} = require('atom');
const etch = require('etch');
const semver = require('semver');
const shell = require('shell');

module.exports = class WelcomeView {
    constructor() {
        this.subscriptions = new CompositeDisposable();

        this.checkCli();
        this.pkgVer = atom.packages.getLoadedPackage('pros').metadata.version;
        this.subscriptions.add(
            atom.tooltips.add(
                this.gaInput,
                {
                    title: `We send anonymous analytics on startup of Atom to track active users.<br/>
                    To disable, uncheck this box or disable telemetry within Atom.`
                }
            )
        );
        this.subscriptions.add(
            atom.tooltips.add(
                this.versions,
                {title: 'Copy version info'}
            )
        );

        etch.initialize(this);
    }
    update() {
        return etch.update(this);
    }
    getTitle() {
        return 'Welcome';
    }
    getURI() {
        return this.uri;
    }
    getIconName() {
        return 'pros';
    }
    checkCli(refresh=false) {
        if (this.cliUpdateSubscriptions) { this.cliUpdateSubscriptions.dispose(); }
        this.cliUpdateSubscriptions = new CompositeDisposable();

        var minVersion = atom
            .packages
            .getLoadedPackage('pros')
            .metadata
            .cli_pros.version;
        this.cliVersion.removeClass('badge-error');
        this.cliVersion.html('<span class=\'loading loading-spinner-tiny inline-block style=\'margin: auto\'></span>');

        this.cliUpdate.removeClass('info error');
        this.cliUpdate.empty();
        if (refresh) {
            std.applyLoading(this.cliUpdate);
        } else {
            this.cliUpdate.hide();
        }

        cli.checkCli({
            minVersion: minVersion,
            fmt: 'raw',
            force: refresh,
            cb: (c, o) => {
                this.cliUpdate.show();
                std.removeLoading(this.cliUpdate);
                let upgradeInstructions;
                switch (c) {
                case 0:
                    this.cliVersion.text(o.version);
                    if (refresh) {
                        atom.notifications.addSuccess('PROS CLI is now up to date');
                    }
                    break;
                case 1:
                    this.cliVersion.text(o.version);
                    this.cliVersion.addClass('badge-error');
                    this.cliUpdate.addClass('info');
                    if (semver.lt(o.version, '2.4.2')) {
                        if (navigator.platform === 'Win32') {
                            upgradeInstructions = 'run C:\\Program Files\\PROS\\update.exe .';
                        } else {
                            upgradeInstructions = 'run <code>pip3 install --upgrade pros-cli</code> from the terminal, or upgrade the CLI the way you installed it.';
                        }
                        this.cliUpdate.html(
                            `<div>
                                <span class=\'icon icon-info\'></span>
                                <div>
                                    PROS CLI is out of date! Some features may not be available.
                                    Update to ${minVersion} to get the latest features and patches.
                                    Future updates will be done through Atom.
                                    <b>To get this update, ${upgradeInstructions}</b>
                                    Then, restart Atom.
                                </div>
                            </div>`
                        );
                        this.cliUpdate
                            .find('#refreshPROSCLI')
                            .click(() => this.checkCli(true));
                    } else {
                        this.cliUpdate.html(
                            `<div>
                                <span class='icon icon-info'></span>
                                <div>
                                    PROS CLI is out of date! Some features may not be available.
                                    Update to ${minVersion} to get the latest features and patches.
                                </div>
                                <div class='actions'>
                                    <div class='btn-group'>
                                        <button class='btn btn-primary icon icon-cloud-download' id='downloadPROSUpdate'>
                                            Install
                                        </button>
                                        <button class='btn icon icon-sync' id='refreshPROSCLI'>
                                            Refresh
                                        </button>
                                    </div>
                                </div>
                            </div>`
                        );
                        this.cliUpdate
                            .find('#downloadPROSUpdate')
                            .click(() => {
                                cli.invUpgrade({
                                    cb: (c, o, e) => {
                                        console.log({c, o, e});
                                    }
                                });
                            });
                        this.cliUpdate
                            .find('#refreshPROSCLI')
                            .click(() => this.checkCli(true));
                    }
                    break;
                case 2:
                    this.cliVersion.text('Error!');
                    this.cliVersion.addClass('badge-error');
                    this.cliUpdate.html(
                        `<div>
                            <span class='icon icon-stop'></span>
                            <div>
                                PROS CLI was not found on your PATH!<br/>
                                Make sure PROS CLI is installed and available on PATH.
                            </div>
                            <div class='actions'>
                                <div class='btn-group'>
                                    <button class='btn btn-primary icon icon-sync' id='restartAtomButton'>
                                        Restart Atom
                                    </button>
                                    <button class='btn btn-primary icon icon-globe' id='goToTroubleshootingPath'>
                                        Learn more
                                    </button>
                                </div>
                            </div>
                        </div>`
                    );
                    this.cliUpdate
                        .find('#goToTroubleshootingPath')
                        .click(() =>
                            shell.openExternal('http://pros.cs.purdue.edu/known-issues')
                        );
                    this.cliUpdate
                        .find('#restartAtomButton')
                        .click(() => atom.restartApplication());
                    break;
                case 3:
                    this.cliVersion.text('Error!');
                    this.cliVersion.addClass('badge-error');
                    this.cliUpdate.addClass('error');
                    this.cliUpdate.html(
                        `<div>
                            <span class='icon icon-stop'></span>
                            <div>
                                PROS CLI thre an error before returning the version.<br/>
                                Visit <a href='http://pros.cs.purdue.edu/known-issues'>pros.cs.purdue.edu/known-issues</a> for troubleshooting steps
                            </div>
                            <div class='actions'>
                                <div class='btn-group'>
                                    <button class='btn btn-primary icon icon-globe' id='goToTroubleshootingPath'></button>
                                    <button class='btn icon icon-clippy' id='copyOutput'></button>
                                    <button class='btn icon icon-sync' id='refreshPROSCLI'></button>
                                </div>
                            </div>
                        </div>`
                    );
                    this.cliUpdateSubscriptions
                        .add(
                            atom.tooltips.add(
                                this.cliUpdate.find('#goToTroubleshootingPath'),
                                {title: 'Learn more'})
                        );
                    this.cliUpdateSubscriptions
                        .add(
                            atom.tooltips.add(
                                this.cliUpdate.find('#copyOutput'),
                                {title: 'Copy error message'}
                            )
                        );
                    this.cliUpdateSubscriptions
                        .add(
                            atom.tooltips.add(
                                this.cliUpdate.find('Refresh'),
                                {title: 'Refresh'}
                            )
                        );
                    this.cliUpdate
                        .find('#goToTroubleshootingPath')
                        .click(() =>
                            shell.openExternal('http://pros.cs.purdue.edu/known-issues')
                        );
                    this.cliUpdate
                        .find('#copyOutput')
                        .click(() =>
                            atom.clipboard.write(`PROS CLI failed to return a version. ${(require('os').EOL)}${o.extra}`)
                        );
                    break;
                default:
                    this.cliVersion.text('Error!');
                    this.cliVersion.addClass('badge-error');
                }
            }
        });
    }
    render() {
        return (
            <div class="pros-welcome">
                <div class="container">
                    <header class="header">
                        {brand.tuxFullColor}
                        {brand.text}
                        <h1 class="title">
                            Open Source C Development for the VEX Cortex
                        </h1>
                    </header>
                    <section class="cli-update" ref={(elem) => this.cliUpdate = elem}></section>
                    <section class="panel">
                        <p>For help, please visit:</p>
                        <ul>
                            <li>
                                <a onclick={() => shell.openExternal('http://pros.cs.purdue.edu/gettigetting-started')}>This page</a> for a guide to getting started with PROS for Atom.
                            </li>
                            <li>
                                The <a onclick={() => shell.openExternal('http://pros.cs.purdue.edu/tutorials')}>PROS tutorial page</a> to learn about using everything from analog sensors to tasks and multithreading in PROS.
                            </li>
                            <li>
                                The <a onclick={() => shell.openExternal('https://pros.cs.purdue.edu/api')}>PROS API documentation</a>.
                            </li>
                        </ul>
                        <div class="welcome-settings">
                            <form>
                                <label>
                                    <input type="checkbox" class="input-checkbox" id="pros-welcome-on-startup" checked={atom.config.get('pros.welcome.enabled')} onchange={() => atom.config.set('pros.welcome.enabled', this.checked)}/>
                                    Show Welcome for PROS when opening Atom
                                </label>
                                <br/>
                                <label>
                                    <input type="checkbox" class="input-checkbox" id="pros-ga-enabled" checked={atom.config.get('pros.googleAnalytics.eenabled')} onchange={() => atom.config.set('pros.googleAnalytics.enabled', this.checked)} ref={(elem) => this.gaInput = elem}/>
                                    Send anonymous usage statistics
                                </label>
                            </form>
                        </div>
                        <div class="versions" onclick={() => atom.clipboard.write(`PROS CLI: ${this.cliVersion.text()} - Package: ${this.pkgVer}`)}, ref={(elem) => this.versions = elem}>
                            <div>
                                <div class="block">
                                    <span>CLI</span>
                                    <span class="badge badge-flexible" ref={(elem) => this.cliVersion = elem}>
                                        <span class="loading loading-spinner-tiny inline-block" style="margin: auto"></span>
                                    </span>
                                </div>
                                <div class="block">
                                    <span>Plugin</span>
                                    <span class="badge badge-flexible">
                                        {this.pkgVer}
                                        <span class="loading loading-spinner-tiny inline-block"></span>
                                    </span>
                                </div>
                            </div>
                        </div>
                    </section>
                    <footer class="footer">
                        <a onclick={() => shell.openExternal('https://pros.cs.purdue.edu')}>pros.cs.purdue.edu</a>
                        <span class="text-subtle">x</span>
                        <a class="icon icon-octoface" onclick={() => shell.openExternal('https://github.com/purduesigbots')}></a>
                    </footer>
                </div>
            </div>
        );
    }
};
