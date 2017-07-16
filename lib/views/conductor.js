/*
 * decaffeinate suggestions:
 * DS001: Remove Babel/TypeScript constructor workaround
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let ConductorView;
const {CompositeDisposable, Disposable} = require('atom');
const {$, View, ScrollView, TextEditorView} = require('atom-space-pen-views');
const fs = require('fs-plus');
const path = require('path');
const commandExists = require('command-exists');
const brand = require('./brand');
const utils = require('../utils');
const async = require('async');
const std = require('./standard');

const cli = require('../proscli');
const {prosConduct} = cli;

module.exports =
  (ConductorView = (function() {
    ConductorView = class ConductorView extends ScrollView {
      constructor(...args) {
        {
          // Hack: trick Babel/TypeScript into allowing this before super.
          if (false) { super(); }
          let thisFn = (() => { this; }).toString();
          let thisName = thisFn.slice(thisFn.indexOf('{') + 1, thisFn.indexOf(';')).trim();
          eval(`${thisName} = this;`);
        }
        this.updateDepotConfig = this.updateDepotConfig.bind(this);
        super(...args);
      }

      static initClass() {
  
        this.prototype.updateDepotCount = 0;
      }
      static content() {
        return this.div({class: 'pros-conductor-parent'}, () => {
          this.div({class: 'ribbon-wrapper'}, () => {
            return this.div({class: 'ribbon'}, () => this.raw('BETA'));
          });
          return this.div({class: "pros-conductor", outlet: 'conductorDiv'}, () => {
            this.div({class: "header"}, () => {
              this.raw(brand.tuxFullColor);
              return this.div({class: "title"}, () => {
                this.h1('PROS Conductor');
                return this.h2('Project Management');
              });
            });

            this.div({class: "project-selector"}, () => {
              this.button({class: 'btn btn-primary icon icon-file-directory-create inline-block-tight',
              outlet: 'createNew'
            },   () => this.raw('New Project'));
              this.button({class: 'btn btn-primary icon icon-device-desktop inline-block-tight',
              outlet: 'addExisting'
            }, () => this.raw('Add Existing'));
              return this.ul({class: 'recent-projects', outlet: 'projectSelector'});
            });

            this.div({class: "project", outlet: 'projectDiv'}, () => {
              this.h2({outlet: 'projectHeader'});
              return this.div(() => {
                this.div({class: 'kernel'}, () => {
                  this.h3('Kernel');
                  return this.div(() => {
                    this.div(() => {
                      this.span({class: 'inline-block-tight icon icon-check'});
                      this.span({class: 'inline-block-tight icon icon-move-up'});
                      return this.div({outlet: 'projectKernel'});
                    });
                    return this.div({class: 'btn-group'}, () => {
                      return this.button({class: 'inline-block-tight btn icon icon-move-up', outlet: 'upgradeProjectButton'},
                        () => this.raw('Upgrade'));
                    });
                  });
                });
                return this.div({class: 'libraries'}, () => {
                  this.div(() => {
                    this.h3('Libraries');
                    return this.button({class: 'inline-block-tight btn icon icon-file-add',
                    outlet: 'addLibraryButton'
                  }, () => this.raw('Add'));
                  });
                  return this.ul({class: 'list-group', outlet: 'projectLibraries'});
                });
              });
            });
            this.hr();
            return this.div({class: 'global', outlet: 'globalDiv'}, () => {
              this.div({class: 'header'}, () => {
                this.h2('Global Configuration');
                return this.div({class: 'btn-group'}, () => {
                  return this.button({outlet: 'refreshGlobal', class: 'btn btn-sm icon icon-sync'});
                });
              });
              return this.div(() => {
                this.div({class: 'kernel', outlet: 'globalKernelsDiv'}, () => {
                  this.h3('Kernels');
                  return this.table({class: 'list-group'}, () => {
                    this.thead(() => {
                      this.td({class: 'version'}, 'Version');
                      this.td({class: 'depot'}, 'Depot');
                      this.td();
                      return this.td();
                    });
                    return this.tbody({outlet: 'globalKernels'});
                  });
                });
                this.div({class: 'libraries', outlet: 'globalLibraryDiv'}, () => {
                  this.h3('Libraries');
                  return this.table({class: 'list-group'}, () => {
                    this.thead(() => {
                      this.td({class: 'name'}, 'Name');
                      this.td({class: 'version'}, 'Version');
                      this.td({class: 'depot'}, 'depot');
                      this.td();
                      return this.td();
                    });
                    return this.tbody({outlet: 'globalLibraries'});
                  });
                });
                return this.div({class: 'depots', outlet: 'globalDepotDiv'}, () => {
                  this.div({class: 'header'}, () => {
                    this.h3('Depots');
                    return this.div({class: 'btn-group btn-group-sm'}, () => {
                      this.button({class: 'btn icon icon-file-add',
                      outlet: 'addDepotButton'
                    }, () => this.raw('Add'));
                      return this.button({class: 'btn icon icon-trashcan', disabled: true,
                      outlet: 'removeDepotButton'
                    }, () => this.raw('Remove'));
                    });
                  });
                  this.ul({class: 'list-group', outlet: 'globalDepots'});
                  this.h4({outlet: 'selectedDepotHeader'});
                  this.span({outlet: 'selectedDepotStatus', class: 'inline-block depot-status icon icon-check'});
                  return this.div({class:'depot-config', outlet: 'selectedDepotConfig'});
                });
              });
            });
          });
        });
      }

      libItem(name, version, latest) {
        return `<li class='${latest ? 'text-success' : 'text-warning'}'> \
<span class='inline-block-tight icon icon-check'></span> \
<span class='inline-block-tight icon icon-move-up'></span> \
${name}-${version} \
</li>`;
      }

      globalKernelItem(version, depot, offline, online) {
        return `<tr class='download-item' data-name='kernel' data-version='${version}' data-depot='${depot}'> \
<td class='version'>${version}</td> \
<td class='depot'>${depot}</td> \
<td class='offline'> \
${offline ? "<span class='inline-block-tight icon icon-device-desktop'></span>" : ""} \
</td> \
<td class='online'> \
${online ? "<span class='inline-block-tight icon icon-cloud-download'></span>" : ""} \
</td> \
</tr>`;
      }

      globalLibraryItem(name, version, depot, offline, online) {
        return `<tr class='download-item' data-name='${name}' data-version='${version}' data-depot='${depot}'> \
<td class='name'>${name}</td> \
<td class='version'>${version}</td> \
<td class='depot'>${depot}</td> \
<td class='offline'> \
${offline ? "<span class='inline-block-tight icon icon-device-desktop'></span>" : ""} \
</td> \
<td class='online'> \
${online ? "<span class='inline-block-tight icon icon-cloud-download'></span>" : ""} \
</td> \
</tr>`;
      }

      globalDepotItem({name, location, registrar}) {
        const li = $(`<li class='depot-item list-item'>${name}<span class='location'>${location}</span></li>`);
        return li.data({name, location, registrar});
      }

      initialize(param) {
        if (param == null) { param = {}; }
        let {uri, activeProject, activeDepot} = param;
        this.uri = uri;
        super.initialize(...arguments);
        this.subscriptions = new CompositeDisposable;

        std.applyLoading(this.globalDiv);
        std.applyLoading(this.projectDiv);

        return cli.checkCli({minVersion: '2.4.1', fmt: 'html', cb: (c, o) => {
          let _path;
          if (c !== 0) {
            this.subscriptions.add(std.addMessage(this.conductorDiv, o, {error: true}));
            return;
          }
          std.clearMessages(this.conductorDiv);
          // @conductorErrorInfo.removeClass 'enabled'
          this.on('click', '.recent-projects > li', e => {
            return this.updateSelectedPath($(e.target).closest('li').data('path'), true);
          });

          this.initializeGlobalListing();

          this.subscriptions.add(atom.project.onDidChangePaths(() => {
            let needle;
            const prevSelected = this.selected != null ? this.selected.data('path') : undefined;
            this.updateAvailableProjects();
            if ((needle = prevSelected, Array.from(atom.project.getPaths()).includes(needle))) {
              return this.updateSelectedPath(prevSelected);
            } else {
              return this.updateSelectedPath(__guard__(atom.project.getPaths(), x => x[0]));
            }
        }));
          this.addExisting.on('click', () => atom.pickFolder(paths => {
            if (paths) {
              const oldPROSProjects = utils.findOpenPROSProjectsSync();
              for (let p of Array.from(paths)) { atom.project.addPath(p); }
              const newPROSProjects = utils.findOpenPROSProjectsSync().filter(p => !Array.from(oldPROSProjects).includes(p));
              // console.log newPROSProjects
              return this.updateSelectedPath((newPROSProjects != null ? newPROSProjects[0] : undefined) || (this.selected != null ? this.selected.data('path') : undefined));
            }
          })
          );
          this.createNew.on('click', () => new (require('./new-project'))({cb: (complete, path) => {
            // process.nextTick to let onDidChangePaths process
            if (complete) { return process.nextTick(() => this.updateSelectedPath(path)); }
          }
          })
          );
          this.addLibraryButton.on('click', () => {
            _path = this.selected != null ? this.selected.data('path') : undefined;
            if (_path) { return new (require('./add-library'))({_path, cb: complete => {
              if (complete) { return this.updateSelectedPath(null, true); }
            }
            }); }
          });
          this.upgradeProjectButton.on('click', () => {
            _path = this.selected != null ? this.selected.data('path') : undefined;
            if (_path) { return new (require('./upgrade-project'))({dir: _path, cb: complete => {
              if (complete) { return this.updateSelectedPath(null, true); }
            }
            }); }
          });

          this.updateAvailableProjects();
          if (activeProject == null) { activeProject = __guard__(atom.project.getPaths(), x => x[0]); }
          this.updateSelectedPath(activeProject);
          std.removeLoading(this.globalDiv);
          this.updateGlobalKernels();
          this.updateGlobalLibraries();
          return this.updateGlobalDepots(activeDepot);
        }
        });
      }

      updateAvailableProjects() {
        const projects = utils.findOpenPROSProjectsSync();
        this.projectSelector.empty();
        return (() => {
          const result = [];
          for (let project of Array.from(projects)) {
            this.projectSelector.append(`<li data-path='${project}'><div> \
<div class='name'>${path.basename(project)}</div> \
<div class='dir'>${path.dirname(project)}</div> \
</div></li>`
            );
            result.push(this.subscriptions.add(atom.tooltips.add(this.projectSelector.children().last(), {title: project})));
          }
          return result;
        })();
      }

      // does all the necessary view updates when the project path is changed. What normally would happen if
      // used data binding
      updateSelectedPath(project, forceUpdate) {
        let oldPath;
        if (forceUpdate == null) { forceUpdate = false; }
        if (!project && !this.selected) {
          $('.pros-conductor .project').addClass('disabled');
          return;
        }
        if (project) {
          $('.pros-conductor .project').removeClass('disabled');
          let newSelected = this.projectSelector.children(`li[data-path="${project.replace(/\\/g, "\\\\")}"]`);
          if (!newSelected || (newSelected.length === 0)) {
            newSelected = this.projectSelector.children().first();
          }
          if (this.selected != null) {
            this.selected.removeClass('selected');
          }
          newSelected.addClass('selected');
          oldPath = this.selected != null ? this.selected.data('path') : undefined;
          this.selected = newSelected;

          // scroll projectSelector if selected isn't in view
          const idx = this.projectSelector.children().index(this.selected);
          if (((idx * this.selected.width()) < this.projectSelector.scrollLeft()) ||
             (((idx + 1) * this.selected.width()) > (this.projectSelector.scrollLeft() + this.projectSelector.width()))) {
            this.projectSelector.animate({ scrollLeft: idx * this.selected.width() }, 100);
          }
        }

        if (((this.selected != null ? this.selected.data('path') : undefined) === oldPath) && !forceUpdate) { return; }
        this.activeProject = (project = this.selected.data('path'));
        this.projectHeader.text(`${path.basename(project)} (${project})`);
        std.applyLoading(this.projectDiv);
        return cli.execute({
          cmd: prosConduct('info-project', project, '--machine-output'),
          cb: (c, o, e) => {
            if (c === 0) {
              let info;
              for (e of Array.from((o != null ? o.split(/\r?\n/).filter(Boolean) : undefined))) { info = (JSON.parse(e)); }
              std.clearMessages(this.projectDiv);
              // @projectErrorInfo.parent().removeClass 'enabled'
              // set active project again in case user starts clicking between projects quickly
              this.activeProject = (project = this.selected.data('path'));
              this.projectHeader.text(`${path.basename(project)} (${project})`);
              this.projectKernel.text(info.kernel);
              if (info.kernelUpToDate) {
                this.projectKernel.parent().addClass('text-success');
                this.projectKernel.parent().removeClass('text-warning');
              } else {
                this.projectKernel.parent().addClass('text-warning');
                this.projectKernel.parent().removeClass('text-success');
              }

              this.projectLibraries.empty();

              if (Object.keys(info.libraries).some(k => info.libraries.hasOwnProperty(k))) {
                for (let n in info.libraries) {
                  const v = info.libraries[n];
                  this.projectLibraries.append(this.libItem(n, v.version, v.latest));
                }
              } else {
                this.projectLibraries.append("<ul class='background-message'>No libraries added</ul>");
              }
              return std.removeLoading(this.projectDiv);
            } else {
              std.removeLoading(this.projectDiv);
              return this.subscriptions.add(std.addMessage(this.projectDiv, `STDOUT:\n${o}\n\nERR:\n${e}`, {error: true}));
            }
          }
        });
      }

      initializeGlobalListing() {
        this.selectedDepotStatus.hide();
        this.on('click', '.global .download-item .icon-cloud-download', e => {
          const template = $(e.target).closest('tr').data();
          return cli.execute({
            cmd: prosConduct('download', template.name, template.version, template.depot),
            cb: (c, o, e) => {
              if (c === 0) {
                atom.notifications.addSuccess(`Downloaded kernel ${template.version}`);
                return this.updateGlobalLibraries();
              }
            }
          });
      });
        this.on('click', '.global .depot-item', e => {
          this.selectedDepotStatus.show();
          this.selectedDepotStatus.removeClass('icon-sync icon-stop');
          this.selectedDepotStatus.addClass('icon-check');
          if (this.selectedDepot != null) {
            this.selectedDepot.removeClass('selected-depot');
          }
          this.selectedDepot = $(e.target).closest('li');
          this.selectedDepot.addClass('selected-depot');
          const depot = this.selectedDepot.data();
          this.removeDepotButton.prop('disabled', depot.name === 'pros-mainline');
          this.selectedDepotHeader.text(`${depot.name} uses ${depot.registrar} at ${depot.location}`);
          return std.createDepotConfig(this.selectedDepotConfig, this.updateDepotConfig, depot);
        });
        this.addDepotButton.click(() => {
          return new (require('./add-depot'))({cb: ({complete, name}) => {
            if (complete) {
              this.updateGlobalKernels();
              this.updateGlobalLibraries();
              return this.updateGlobalDepots(name);
            }
          }
          });
        });
        this.removeDepotButton.click(() => {
          return cli.execute({
            cmd: prosConduct('rm-depot', '--name', this.selectedDepot.data('name')),
            cb: (c, o, e) => {
              if (c !== 0) {
                return atom.notifications.addError(`Failed to remove ${this.selectedDepot.data('name')}`, {
                  detail: `OUT:\n${o}\n\nERR:\n${e}`,
                  dismissable: true
                }
                );
              } else {
                atom.notifications.addSuccess(`Successfully removed ${this.selectedDepot.data('name')}`);
                this.updateGlobalDepots(this.selectedDepot != null ? this.selectedDepot.data('name') : undefined);
                this.updateGlobalKernels();
                return this.updateGlobalLibraries();
              }
            }
          });
      });
        return this.refreshGlobal.click(() => {
          this.updateGlobalKernels();
          this.updateGlobalLibraries();
          return this.updateGlobalDepots(this.selectedDepot != null ? this.selectedDepot.data('name') : undefined);
        });
      }


      updateGlobalKernels() {
        std.applyLoading(this.globalKernelsDiv);
        return cli.execute({
          cmd: prosConduct('lstemplate', '--kernels', '--machine-output'),
          cb: (c, o, e) => {
            std.removeLoading(this.globalKernelsDiv);
            std.clearMessages(this.globalKernelsDiv);
            if (c === 0) {
              let listing = [];
              for (e of Array.from((o != null ? o.split(/\r?\n/).filter(Boolean) : undefined))) {
                try {
                  listing = listing.concat(JSON.parse(e));
                } catch (err) {
                  this.subscriptions.add(std.addMessage(this.globalKernelsDiv, `Error parsing: ${e} (${err})`,
                    {nohide: true})
                  );
                }
              }
              // listing = (try JSON.parse e catch error ) for e in o?.split(/\r?\n/).filter(Boolean)
              this.globalKernels.empty();
              if (listing.length === 0) {
                return this.subscriptions.add(std.addMessage(this.globalKernelsDiv,
                  `You don't have any depots which provide kernels. \
Add a depot that provides libraries to get started.`
                )
                );
              } else {
                return (() => {
                  const result = [];
                  for (let {version, depot, offline, online} of Array.from(listing)) {
                    result.push(this.globalKernels.append(this.globalKernelItem(version, depot, offline, online)));
                  }
                  return result;
                })();
              }
            } else {
              return this.subscriptions.add(std.addMessage(this.globalLibraryDiv,
                `There was an error fetching the kernels listing:<br/>${o}<br/>${e}`,
                {error: true})
              );
            }
          }
        });
      }

      updateGlobalLibraries() {
        std.applyLoading(this.globalLibraryDiv);
        return cli.execute({
          cmd: prosConduct('lstemplate', '--libraries', '--machine-output'),
          cb: (c, o, e) => {
            std.removeLoading(this.globalLibraryDiv);
            std.clearMessages(this.globalLibraryDiv);
            if (c === 0) {
              let listing = [];
              for (e of Array.from((o != null ? o.split(/\r?\n/).filter(Boolean) : undefined))) {
                try {
                  listing = listing.concat(JSON.parse(e));
                } catch (err) {
                  this.subscriptions.add(std.addMessage(this.globalLibraryDiv, `Error parsing: ${e} (${err})`,
                  {nohide: true})
                  );
                }
              }
              this.globalLibraries.empty();
              if (listing.length === 0) {
                return this.subscriptions.add(std.addMessage(this.globalLibraryDiv,
                  `You don't have any depots which provide libraries.<br/> \
Add a depot that provides depots to get started.`
                )
                );
              } else {
                return (() => {
                  const result = [];
                  for (let {library, version, depot, offline, online} of Array.from(listing)) {
                    result.push(this.globalLibraries.append(this.globalLibraryItem(library, version, depot, offline, online)));
                  }
                  return result;
                })();
              }
            } else {
              return this.subscriptions.add(std.addMessage(this.globalLibraryDiv,
                `There was an error fetching the libraries listing: \
<br/>STDOUT:<br/>${o}<br/><br/>ERR:<br/>${e}`,
                {error: true})
              );
            }
          }
        });
      }

      updateGlobalDepots(prevSelected) {
        // console.log prevSelected
        std.applyLoading(this.globalDepotDiv);
        return cli.execute({
          cmd: prosConduct('ls-depot', '--machine-output'),
          cb: (c, o, e) => {
            std.removeLoading(this.globalDepotDiv);
            if (c === 0) {
              let listing = [];
              try {
                listing = listing.concat(JSON.parse(o));
              } catch (err) {
                this.subscriptions.add(std.addMessage(this.globalDepotDiv, `Error parsing: ${e} (${err})`, {nohide: true}));
              }
              this.globalDepots.empty();
              if (listing.length === 0) {
                return this.subscriptions.add(std.addMessage(this.globalDepotDiv,
                  `You don't have any depots configured. Run \
<span class='inline-block highlight'>pros conduct first-run</span> to automatically set up \
the default PROS depot, or restart Atom and it will be automatically configured for you.`,
                  {nohide: true})
                );
              } else {
                for (let depot of Array.from(listing)) {
                  const item = this.globalDepotItem(depot);
                  this.globalDepots.append(item);
                  if (depot.name === prevSelected) {
                    prevSelected = null;
                    item.click();
                  }
                }
                if (prevSelected !== null) {
                  return this.globalDepots.children().first().click();
                }
              }
            } else {
              return this.subscriptions.add(std.addMessage(this.globalDepotDiv,
                `There was an error fetching the configured depots: \
<br/>STDOUT:<br/>${o}<br/><br/>ERR:<br/>${e}`,
                {error: true})
              );
            }
          }
        });
      }
      updateDepotConfig(depot, key, value) {
        this.selectedDepotStatus.removeClass('icon-check icon-stop');
        this.selectedDepotStatus.addClass('icon-sync');
        this.updateDepotCount += 1;
        return cli.execute({
          cmd: prosConduct('set-depot-key', depot.toString(), key.toString(), value.toString()),
          cb: (c, o, e) => {
            std.clearMessages(this.selectedDepotConfig);
            if (c !== 0) {
              std.addMessage(this.selectedDepotConfig,
                `Error setting ${key} to ${value}<br/>STDOUT:<br/>${o}<br/><br/>ERR:<br/>${e}`,
                {nohide: true});
              this.selectedDepotStatus.removeClass('icon-check icon-sync');
              this.selectedDepotStatus.addClass('icon-stop');
              return;
            }
            this.updateDepotCount -= 1;
            if (this.updateDepotCount === 0) {
              this.selectedDepotStatus.removeClass('icon-stop icon-sync');
              this.selectedDepotStatus.addClass('icon-check');
              this.updateGlobalKernels();
              return this.updateGlobalLibraries();
            }
          }
        });
      }

      serialize() {
        return {
          deserializer: this.constructor.name,
          version: 1,
          activeProject: (this.selected != null ? this.selected.data('path') : undefined),
          activeDepot: (this.selectedDepot != null ? this.selectedDepot.data('name') : undefined),
          uri: this.uri
        };
      }

      getURI() { return this.uri; }
      getTitle() { return "Conductor"; }
      getIconName() { return 'pros'; }
    };
    ConductorView.initClass();
    return ConductorView;
  })());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}