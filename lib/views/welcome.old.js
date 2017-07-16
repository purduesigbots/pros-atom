/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let WelcomeView;
const {CompositeDisposable, Disposable} = require('atom');
const {$, ScrollView} = require('atom-space-pen-views');
const semver = require('semver');
const shell = require('shell');
const {BaseView} = require('./base-view');
const utils = require('../utils');
const cli = require('../proscli');
const brand = require('./brand');
const std = require('./standard');

module.exports =
  (WelcomeView = class WelcomeView extends ScrollView {
      static content() {
          return this.div({class:'pros-welcome'}, () => {
              return this.div({class:'container'}, () => {
                  this.header({class:'header'}, () => {
                      this.raw(brand.tuxFullColor);
                      this.raw(brand.text);
                      return this.h1({class: 'title'}, () => this.raw('Open Source C Development for the VEX Cortex'));
                  });
                  this.section({class: 'cli-update', outlet: 'cliUpdateOutlet'});
                  this.section({class:'panel'}, () => {
                      this.p('For help, please visit:');
                      this.ul(() => {
                          this.li(() => {
                              this.a({outlet: 'gettingStarted'}, () => this.raw('This page'));
                              return this.raw(' for a guide to getting started with PROS for Atom.');
                          });
                          this.li(() => {
                              this.raw('The ');
                              this.a({outlet: 'tutorials'}, () => this.raw('PROS tutorial page'));
                              return this.raw(' to learn about using everything from analog sensors to tasks and \
multithreading in PROS.'
                              );
                          });
                          return this.li(() => {
                              this.raw('The ');
                              this.a({outlet: 'api'}, () => this.raw('PROS API documentation'));
                              return this.raw('.');
                          });
                      });
                      this.div({class: 'welcome-settings'}, () => {
                          return this.form(() => {
                              this.label(() => {
                                  this.input({type: 'checkbox', class: 'input-checkbox', id: 'pros-welcome-on-startup'});
                                  return this.raw('Show Welcome for PROS when opening Atom');
                              });
                              this.br();
                              return this.label({outlet: 'gaInput'}, () => {
                                  this.input({type: 'checkbox', class: 'input-checkbox', id: 'pros-ga-enabled'});
                                  return this.raw('Send anonymous usage statistics');
                              });
                          });
                      });
                      return this.div({outlet: 'versions', class: 'versions'}, () => {
                          return this.div(() => {
                              this.div({class: 'block'}, () => {
                                  this.span('CLI: ');
                                  return this.span({class: 'badge badge-flexible', outlet: 'cliVersion'}, () => {
                                      return this.span({class: 'loading loading-spinner-tiny inline-block', style: 'margin: auto'});
                                  });
                              });
                              return this.div({class: 'block'}, () => {
                                  this.span('Plugin: ');
                                  return this.span({class: 'badge badge-flexible', outlet: 'pkgVersion'}, () => {
                                      return this.span({class: 'loading loading-spinner-tiny inline-block'});
                                  });
                              });
                          });
                      });
                  });
                  return this.footer({class:'footer'}, () => {
                      this.a({outlet: 'home'}, () => this.raw('pros.cs.purdue.edu'));
                      this.span({class: 'text-subtle'}, () => this.raw('×'));
                      return this.a({outlet: 'github', class: 'icon icon-octoface'});
                  });
              });
          });
      }

      initialize() {
          this.subscriptions = new CompositeDisposable;
          this.gettingStarted[0].onclick =() => shell.openExternal('http://pros.cs.purdue.edu/getting-started');
          this.tutorials[0].onclick =() => shell.openExternal('http://pros.cs.purdue.edu/tutorials');
          this.api[0].onclick =() => shell.openExternal('http://pros.cs.purdue.edu/api');
          this.home[0].onclick =() => shell.openExternal('http://pros.cs.purdue.edu');
          this.github[0].onclick =() => shell.openExternal('https://github.com/purduesigbots');

          $(this).find('#pros-welcome-on-startup').prop('checked', atom.config.get('pros.welcome.enabled'));
          $(this).find('#pros-welcome-on-startup').click(() => {
              return atom.config.set('pros.welcome.enabled',
                  $(this).find('#pros-welcome-on-startup').prop('checked'));
          });

          $(this).find('#pros-ga-enabled').prop('checked', atom.config.get('pros.googleAnalytics.enabled'));
          $(this).find('#pros-ga-enabled').click(() => {
              return atom.config.set('pros.googleAnalytics.enabled',
                  $(this).find('#pros-ga-enabled').prop('checked'));
          });

          this.checkCli();
          const pkgVer = (this.pkgVersion[0].textContent = atom.packages.getLoadedPackage('pros').metadata.version);
          this.versions[0].onclick = function() { return atom.clipboard.write(`PROS CLI: ${this.cliVersion.text()} - Package: ${pkgVer}`); };

          this.subscriptions.add(atom.tooltips.add(this.gaInput,
              {
                  title: 'We send anonymous analytics on startup of Atom to track active users.<br/> \
To disable, uncheck this box or disable telemetry within Atom'
              }));
          return this.subscriptions.add(atom.tooltips.add(this.versions[0], {title: 'Copy version info'}));
      }

      checkCli(refresh) {
          if (refresh == null) { refresh = false; }
          if (this.cliUpdateSubscriptions != null) {
              this.cliUpdateSubscriptions.dispose();
          }
          this.cliUpdateSubscriptions = new CompositeDisposable;
          const minVersion = atom.packages.getLoadedPackage('pros').metadata.cli_pros.version;
          this.cliVersion.removeClass('badge-error');
          this.cliVersion.html('<span class=\'loading loading-spinner-tiny inline-block\' style=\'margin: auto\'></span>');
          this.cliUpdateOutlet.removeClass('info error');
          this.cliUpdateOutlet.empty();
          if (refresh) { std.applyLoading(this.cliUpdateOutlet); } else { this.cliUpdateOutlet.hide(); }
          return cli.checkCli({minVersion, fmt: 'raw', force: refresh, cb: (c, o) => {
              this.cliUpdateOutlet.show();
              std.removeLoading(this.cliUpdateOutlet);
              switch (c) {
              case 0:
                  this.cliVersion.text(o.version);
                  if (refresh) {
                      return atom.notifications.addSuccess('PROS CLI is now up to date');
                  }
                  break;
              case 1:
                  this.cliVersion.text(o.version);
                  this.cliVersion.addClass('badge-error');
                  this.cliUpdateOutlet.addClass('info');
                  // coffeelint: disable=max_line_length
                  if (semver.lt(o.version, '2.4.2')) {
                      let upgradeInstructions;
                      if (navigator.platform === 'Win32') {
                          upgradeInstructions = 'run C:\\Program Files\\PROS\\update.exe .';
                      } else {
                          upgradeInstructions = 'run <code>pip3 install --upgrade pros-cli</code> from the terminal, or upgrade the CLI the way you installed it.';
                      }
                      this.cliUpdateOutlet.html(`<div> \
<span class='icon icon-info'></span> \
<div> \
PROS CLI is out of date! Some features may not be available. \
Update to ${minVersion} to get the latest features and patches. \
Future updates will be done through Atom. <b>To get this update, ${upgradeInstructions}</b> Then, restart Atom. \
</div> \
</div>`
                      );
                      return this.cliUpdateOutlet.find('#refreshPROSCLI').click(() => this.checkCli(true));
                  } else {
                      this.cliUpdateOutlet.html(`<div> \
<span class='icon icon-info'></span> \
<div> \
PROS CLI is out of date! Some features may not be available. \
Update to ${minVersion} to get the latest features and patches. \
</div> \
<div class='actions'> \
<div class='btn-group'> \
<button class='btn btn-primary icon icon-cloud-download' id='downloadPROSUpdate'> \
Install \
</button> \
<button class='btn icon icon-sync' id='refreshPROSCLI'> \
Refresh \
</button> \
</div> \
</div> \
</div>`
                      );
                      this.cliUpdateOutlet.find('#downloadPROSUpdate').click(() => cli.invUpgrade({cb(c, o, e) {
                          return console.log({c, o, e});
                      }}) );
                      return this.cliUpdateOutlet.find('#refreshPROSCLI').click(() => this.checkCli(true));
                  }
                  // coffeelint: enable=max_line_length
              case 2:
                  this.cliVersion.text('Error!');
                  this.cliVersion.addClass('badge-error');
                  this.cliUpdateOutlet.addClass('error');
                  // coffeelint: disable=max_line_length
                  this.cliUpdateOutlet.html('<div> \
<span class=\'icon icon-stop\'></span> \
<div> \
PROS CLI was not found on your PATH!<br/> \
Make sure PROS CLI is installed and available on PATH. \
</div> \
<div class=\'actions\'> \
<div class=\'btn-group\'> \
<button class=\'btn btn-primary icon icon-sync\' id=\'restartAtomButton\'> \
Restart Atom \
</button> \
<button class=\'btn btn-primary icon icon-globe\' id=\'goToTroubleshootingPath\'> \
Learn more \
</button> \
</div> \
</div> \
</div>'
                  );
                  // coffeelint: enable=max_line_length
                  this.cliUpdateOutlet.find('#goToTroubleshootingPath').click(() => shell.openExternal('http://pros.cs.purdue.edu/known-issues'));
                  return this.cliUpdateOutlet.find('#restartAtomButton').click(() => atom.restartApplication());
              case 3:
                  this.cliVersion.text('Error!');
                  this.cliVersion.addClass('badge-error');
                  this.cliUpdateOutlet.addClass('error');
                  // coffeelint: disable=max_line_length
                  this.cliUpdateOutlet.html('<div> \
<span class=\'icon icon-stop\'></span> \
<div> \
PROS CLI threw an error before returning the version.<br/> \
Visit <a href=\'http://pros.cs.purdue.edu/known-issues\'>pros.cs.purdue.edu/known-issues</a> for troubleshooting steps \
</div> \
<div class=\'actions\'> \
<div class=\'btn-group\'> \
<button class=\'btn btn-primary icon icon-globe\' id=\'goToTroubleshootingPath\'></button> \
<button class=\'btn icon icon-clippy\' id=\'copyOutput\'></button> \
<button class=\'btn icon icon-sync\' id=\'refreshPROSCLI\'></button> \
</div> \
</div> \
</div>'
                  );
                  this.cliUpdateSubscriptions.add(atom.tooltips.add(this.cliUpdateOutlet.find('#goToTroubleshootingPath'), {title: 'Learn more'}));
                  this.cliUpdateSubscriptions.add(atom.tooltips.add(this.cliUpdateOutlet.find('#copyOutput'), {title: 'Copy error message'}));
                  this.cliUpdateSubscriptions.add(atom.tooltips.add(this.cliUpdateOutlet.find('#refreshPROSCLI'), {title: 'Refresh'}));
                  // coffeelint: enable=max_line_length
                  this.cliUpdateOutlet.find('#goToTroubleshootingPath').click(() => shell.openExternal('http://pros.cs.purdue.edu/known-issues'));
                  this.cliUpdateOutlet.find('#copyOutput').click(() => atom.clipboard.write(`PROS CLI failed to return a version.${(require('os')).EOL}${o.extra}`));
                  return this.cliUpdateOutlet.find('#refreshPROSCLI').click(() => this.checkCli(true));
              default:
                  this.cliVersion.text('Error!');
                  return this.cliVersion.addClass('badge-error');
              }
          }
          });
      }

      getURI() { return this.uri; }
      getTitle() { return 'Welcome'; }
      getIconName() { return 'pros'; }
  });
