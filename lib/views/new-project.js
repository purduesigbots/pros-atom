/*
 * decaffeinate suggestions:
 * DS001: Remove Babel/TypeScript constructor workaround
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let cli, NewProjectModal;
const {CompositeDisposable} = require('atom');
const {$, View, TextEditorView} = require('atom-space-pen-views');
const fs = require('fs');
const path = require('path');
const std = require('./standard');
const {prosConduct} = (cli = require('../proscli'));

module.exports =
  (NewProjectModal = class NewProjectModal extends View {
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
      return this.div({class: 'pros-modal pros-new-project'}, () => {
        this.h1('Create a new PROS Project');
        this.div({class: 'directory-selector'}, () => {
          this.h4('Choose a directory:');
          return this.div({style: 'display: flex; flex-direction: row-reverse;'}, () => {
            this.button({class: 'btn btn-default', outlet: 'openDir'}, () => {
              return this.span({class: 'icon icon-ellipsis'});
            });
            return this.subview('projectPathEditor', new TextEditorView({mini: true}));
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
            return this.button({outlet: 'createButton', class: 'btn btn-primary icon icon-rocket'}, 'Create');
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

      this.createButton.prop('disabled', true);
      this.projectPathEditor.getModel().onDidChange(() => {
        return this.createButton.prop('disabled', !!!this.projectPathEditor.getText());
      });

      this.openDir.click(() => atom.pickFolder(paths => {
        if (paths != null ? paths[0] : undefined) {
          return this.projectPathEditor.setText(paths[0]);
        }
    }));

      this.createButton.click(() => {
        if (dir = this.projectPathEditor.getText()) {
          const template = JSON.parse(this.kernelsList.val());
          $(this.element).find('.actions').addClass('working');
          return cli.execute({
            cmd: prosConduct('new', dir, template.version, template.depot),
            cb: (c, o, e) => {
              this.cancel(true); // destroy the modal
              if (c === 0) {
                atom.notifications.addSuccess('Created a new project', {detail: o});
                atom.project.addPath(dir);
                const firstPath = path.join(dir, 'src', 'opcontrol.c');
                return fs.exists(firstPath, function(exists) { if (exists) { return atom.workspace.open(firstPath, {pending: true}); } });
              } else {
                return atom.notifications.addError('Failed to create project', {
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
            this.subscriptions.add(std.addMessage(this.kernelSelector,
              `Error parsing the list of downloaded kernels (${o}).<br/>${error}`, {error: true, nohide: true})
            );
            return;
          }
          if (listing.length === 0) {
            this.subscriptions.add(std.addMessage(this.kernelSelector,
              `You don't have any downloaded kernels.<br/> \
Visit <a>Conductor</a> to download some.`, {nohide: true})
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
