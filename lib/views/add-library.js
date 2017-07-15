/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let AddLibraryModal;
const {CompositeDisposable, Disposable} = require('atom');
const {$, View, TextEditorView} = require('atom-space-pen-views');
const fs = require('fs');
const path = require('path');
const utils = require('../utils');
const proscli = require('../proscli');
const {prosConduct} = proscli;
const std = require('./standard');

module.exports =
  (AddLibraryModal = class AddLibraryModal extends View {
    static content() {
      return this.div({class: 'pros-modal pros-add-library', tabindex: -1}, () => {
        this.h1('Add Library to PROS Project');
        this.h4('Choose a project:');
        this.div({class: 'select-list', id: 'projectPathPicker', outlet: 'projectPathPicker'}, () => {
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
            return Array.from(utils.findOpenPROSProjectsSync()).map((p) => (this.li(p)));
          });
        });
        this.h4('Choose a library:');
        this.div({class: 'library-picker select-list'}, () => {
          return this.ol({class: 'list-group', outlet: 'libraryList'}, () => {
            return this.li('Loading...');
          });
        });
        return this.div({class: 'actions'}, () => {
          this.div({class: 'btn-group'}, () => {
            this.button({outlet: 'cancelButton', class: 'btn'}, 'Cancel');
            return this.button({outlet: 'addButton', class: 'btn btn-primary icon icon-rocket'}, 'Add Library');
          });
          return this.span({class: 'loading loading-spinner-tiny'});
        });
      });
    }


    initialize(param) {
      let result;
      if (param == null) { param = {}; }
      const {_path, cb} = param;
      this.cb = cb;
      if (this.subscriptions == null) { this.subscriptions = new CompositeDisposable; }
      atom.keymaps.add('add-library-keymap', {
        '.pros-add-library': {
          'escape': 'core:cancel'
        }
      }
      );
      atom.commands.add(this.element, 'core:cancel', () => this.cancel());
      if (this.panel == null) { this.panel = atom.workspace.addModalPanel({item: this, visible: false}); }

      this.cancelButton.click(() => this.cancel());

      this.openDir.click(() => atom.pickFolder(paths => {
        if (paths != null ? paths[0] : undefined) {
          this.projectPathEditor.setText(paths[0]);
          return $('#projectPathPicker ol').removeClass('enabled');
        }
      })
      );

      this.toggleListButton.click(() => $('#projectPathPicker ol').toggleClass('enabled'));

      $('#projectPathPicker ol li').on('click', e => {
        this.projectPathEditor.setText(e.target.innerText);
        return $('#projectPathPicker ol').removeClass('enabled');
      });

      const updateDisable = () => {
        if (!!!this.projectPathEditor.getText()) {
          return this.addButton.prop('disabled', true);
        } else if (!fs.existsSync(path.join(this.projectPathEditor.getText(), 'project.pros'))) {
          return this.addButton.prop('disabled', true);
        } else if (!this.selected) {
          return this.addButton.prop('disabled', true);
        } else {
          return this.addButton.prop('disabled', false);
        }
      };

      this.projectPathEditor.getModel().onDidChange(() => {
        updateDisable();
        if (fs.existsSync(path.join(this.projectPathEditor.getText(), 'project.pros'))) {
          return proscli.execute({
            cmd: prosConduct('info-project', this.projectPathEditor.getText()),
            cb: (c, o, e) => {
              if (c !== 0) { return; }
              let info = {};
              try {
                info = JSON.parse(o);
              } catch (error) {
                console.log(error);
                return;
              }
              if (Object.keys(info.libraries).some(k => info.libraries.hasOwnProperty(k))) {
                return (() => {
                  result = [];
                  for (var n in info.libraries) {
                    var v = info.libraries[n];
                    this.libraryList.children('.primary-line.icon-check').removeClass('icon icon-check');
                    result.push((() => {
                      const result1 = [];
                      for (let child of Array.from(this.libraryList.children())) {
                        const value = $(child).data('value');
                        if (((value != null ? value.library : undefined) === n) && ((value != null ? value.version : undefined) === v.version)) {
                          result1.push($(child).children('.primary-line').addClass('icon icon-check'));
                        } else {
                          result1.push(undefined);
                        }
                      }
                      return result1;
                    })());
                  }
                  return result;
                })();
              }
            }
          });
        }
    });

      this.addButton.click(() => {
        const dir = this.projectPathEditor.getText();
        const template = this.selected.data('value');
        $(this.element).find('.actions').addClass('working');
        return proscli.execute({
          cmd: prosConduct('new-lib', `\"${dir}\"`, template.library, template.version, template.depot),
          cb: (c, o, e) => {
            this.cancel(true);
            if (c === 0) {
              atom.notifications.addSuccess(`Added ${template.library} to ${path.basename(dir)}`, {detail: o});
              return atom.project.addPath(dir);
            } else {
              return atom.notifications.addError(`Failed to add ${template.library} to ${path.basename(dir)}`, {
                detail: o,
                dismissable: true
              }
              );
            }
          }
        });
    });

      if (!!_path) { this.projectPathEditor.setText(_path); }
      this.panel.show();
      this.projectPathEditor.focus();

      return proscli.execute({
        cmd: prosConduct('ls-template', '--libraries', '--offline-only', '--machine-output'),
        cb: (c, o, e) => {
          let listing;
          this.libraryList.empty();
          if (c !== 0) {
            this.subscriptions.add(std.addMessage(this.libraryList,
              `Error obtaining the list of libraries downloaded.<br/>STDOUT:<br/>${o}<br/><br/>ERR:<br/>${e}`,
              {error: true})
            );
            return;
          }
          try {
            listing = JSON.parse(o);
          } catch (error1) {
            const error = error1;
            this.subscriptions.add(std.addMessage(this.libraryList,
              `Error parsing the list of downloaded libraries (${o}).<br/>${error}`, {error: true})
            );
            return;
          }
          if (listing.length === 0) {
            this.subscriptions.add(std.addMessage(this.libraryList,
              `You don't have any downloaded libraries.<br/> \
Visit <a>Conductor</a> to download some.`
            )
            );
            this.libraryList.find('a').on('click', () => {
              this.cancel();
              return atom.workspace.open('pros://conductor');
            });
            return;
          }
          return (() => {
            result = [];
            for (let {library, version, depot} of Array.from(listing)) {
              const li = document.createElement('li');
              li.className = 'two-lines library-option';
              li.setAttribute('data-value', JSON.stringify({library, version, depot}));
              li.innerHTML = `\
<div class='primary-line'>${library}</div> \
<div class='secondary-line'><em>version</em> ${version} <em>from</em> \
${depot}</div>`;
              li.click = () => {
                if (this.selected != null) {
                  this.selected.removeClass('selected');
                }
                if (this.selected != null) {
                  this.selected.children('.primary-line').removeClass('icon icon-chevron-right');
                }
                this.selected = $(e.target).closest('li.library-option');
                updateDisable();
                this.selected.addClass('selected');
                return this.selected.children('.primary-line').addClass('icon icon-chevron-right');
              };
              result.push(this.libraryList.append(li));
            }
            return result;
          })();
        }
      });
    }

    cancel(complete){
      if (complete == null) { complete = false; }
      if (this.panel != null) {
        this.panel.hide();
      }
      if (this.panel != null) {
        this.panel.destroy();
      }
      this.panel = null;
      atom.workspace.getActivePane().activate();
      return (typeof this.cb === 'function' ? this.cb(complete) : undefined);
    }
  });
