/*
 * decaffeinate suggestions:
 * DS001: Remove Babel/TypeScript constructor workaround
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let cli, UpgradeProjectModal;
const {CompositeDisposable} = require('atom');
const {$, View, TextEditorView} = require('atom-space-pen-views');
const fs = require('fs');
const path = require('path');
const {prosConduct} = (cli = require('../proscli'));
const std = require('./standard');
const utils = require('../utils');

module.exports =
  (UpgradeProjectModal = class UpgradeProjectModal extends View {
    constructor(...args) {
      {
        // Hack: trick Babel/TypeScript into allowing this before super.
        if (false) { super(); }
        let thisFn = (() => { this; }).toString();
        let thisName = thisFn.slice(thisFn.indexOf('{') + 1, thisFn.indexOf(';')).trim();
        eval(`${thisName} = this;`);
      }
      this.cancel = this.cancel.bind(this);
      super(...args);
    }

    static content() {
      return this.div({class: 'pros-modal pros-upgrade-project'}, () => {
        this.h1('Upgrade a PROS Project');
        this.div({class: 'directory-selector'}, () => {
          this.h4('Choose a directory:');
          return this.div({class: 'select-list', id: 'projectPathPicker', outlet: 'projectPathPicker'}, () => {
            this.div({style: 'display: flex; flex-direction: row-reverse;'}, () => {
              this.button({class: 'btn btn-default', outlet: 'openDir'}, () => {
                return this.span({class: 'icon icon-ellipsis'});
              });
              this.button({class: 'btn btn-default', outlet: 'toggleListButton'}, () => {
                return this.span({class: 'icon icon-three-bars'});
              });
              return this.subview('projectPathEditor', new TextEditorView({mini: true}));
            });
            return this.ol({class: 'list-group'}, () => {
              return Array.from(atom.project.getPaths()).map((p) => (this.li(p)));
            });
          });
        });
        this.div({class: 'kernel-selector', outlet: 'kernelSelector'}, () => {
          this.h4('Choose a kernel:');
          return this.select({class: 'input-select', outlet: 'kernelsList'}, () => {
            return this.option({class: 'temp'}, 'Loading...');
          });
        });
        return this.div({class: 'actions'}, () => {
          this.div({class: 'btn-group'}, () => {
            this.button({outlet: 'cancelButton', class: 'btn'}, 'Cancel');
            return this.button({outlet: 'registerButton', class: 'btn btn-primary icon icon-rocket'}, 'Register');
          });
          return this.span({class: 'loading loading-spinner-tiny'});
        });
      });
    }

    initialize(param) {
      if (param == null) { param = {}; }
      let {dir, cb} = param;
      this.cb = cb;
      this.subscriptions = new CompositeDisposable;
      atom.keymaps.add('new-project-keymap', {
        '.pros-new-project': {
          'escape': 'core:cancel'
        }
      }
      );
      atom.commands.add(this.element, 'core:cancel', () => this.cancel());
      if (this.panel == null) { this.panel = atom.workspace.addModalPanel({item: this, visible: false}); }

      this.registerButton.prop('disabled', true);
      this.projectPathEditor.getModel().onDidChange(() => {
        return this.registerButton.prop('disabled', !!!this.projectPathEditor.getText());
      });

      this.toggleListButton.click(() => $('#projectPathPicker ol').toggleClass('enabled'));

      this.openDir.click(() => atom.pickFolder(paths => {
        if (paths != null ? paths[0] : undefined) {
          return this.projectPathEditor.setText(paths[0]);
        }
    }));

      this.registerButton.click(() => {
        if (dir = this.projectPathEditor.getText()) {
          const template = JSON.parse(this.kernelsList.val());
          $(this.element).find('.actions').addClass('working');
          return cli.execute({
            cmd: prosConduct('register', dir, template.version),
            cb: (c, o, e) => {
              this.cancel(true); // destroy the modal
              if (c === 0) {
                atom.notifications.addSuccess("Registered a project", {detail: o});
                return atom.project.addPath(dir);
              } else {
                return atom.notifications.addError('Failed to upgrade project', {
                  detail: `OUT:\n${o}\n\nERR:${e}`,
                  dismissable: true
                }
                );
              }
            }
          });
        }
    });

      this.cancelButton.click(() => this.cancel());

      if (dir) { this.projectPathEditor.setText(dir); }
      let option = document.createElement('option');
      option.value = JSON.stringify({'depot': 'auto', 'version': 'latest'});
      option.innerHTML = 'Auto-select latest';
      this.kernelsList.prepend(option);
      this.panel.show();
      this.projectPathEditor.focus();

      return cli.execute({
        cmd: prosConduct('ls-template', '--kernels', '--offline-only', '--machine-output'),
        cb: (c, o, e) => {
          let listing;
          if (c !== 0) {
            this.subscriptions.add(std.addMessage(this.kernelSelector,
              `Error obtaining the list of kernels downloaded.<br/>STDOUT:<br/>${o}<br/><br/>ERR:<br/>${e}`,
              {error: true, nohide: true})
            );
            return;
          }
          try {
            listing = JSON.parse(o);
          } catch (error1) {
            const error = error1;
            this.subscriptions.add(std.addMessage(this.kernelsList,
              `Error parsing the list of downloaded kernels (${o}).<br/>${error}`, {error: true})
            );
            return;
          }
          if (listing.length === 0) {
            this.subscriptions.add(std.addMessage(this.kernelsList,
              `You don't have any downloaded kernels.<br/> \
Visit <a>Conductor</a> to download some.`
            )
            );
            this.kernelsList.find('a').on('click', () => {
              this.cancel();
              return atom.workspace.open('pros://conductor');
            });
            return;
          }
          this.kernelsList.children().last().remove();
          return listing.forEach(kernel => {
            option = document.createElement('option');
            option.value = JSON.stringify(kernel);
            option.innerHTML = `${kernel.version} from ${kernel.depot}`;
            return this.kernelsList.append(option);
          });
        }
        });
    }

    cancel(cancel){
      if (cancel == null) { cancel = false; }
      if (this.panel != null) {
        this.panel.hide();
      }
      if (this.panel != null) {
        this.panel.destroy();
      }
      this.panel = null;
      atom.workspace.getActivePane().activate();
      return (typeof this.cb === 'function' ? this.cb(cancel, this.projectPathEditor.getText()) : undefined);
    }
  });
