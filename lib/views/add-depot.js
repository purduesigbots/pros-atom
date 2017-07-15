/*
 * decaffeinate suggestions:
 * DS001: Remove Babel/TypeScript constructor workaround
 * DS102: Remove unnecessary code created because of implicit returns
 * DS203: Remove `|| {}` from converted for-own loops
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let AddDepotModal;
const {CompositeDisposable} = require('atom');
const {$, ScrollView, TextEditorView} = require('atom-space-pen-views');
const fs = require('fs');
const cli = require('../proscli');
const std = require('./standard');

module.exports =
  (AddDepotModal = (function() {
    AddDepotModal = class AddDepotModal extends ScrollView {
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
  
        this.prototype.depotConfig = {};
      }
      static content() {
        return this.div({class: 'pros-modal pros-add-depot', tabindex: -1}, () => {
          this.h1('Add a new PROS Depot');
          this.h4('Choose a registrar:');
          this.div({class: 'registrar-picker select-list'}, () => {
            return this.ol({class: 'list-group', outlet: 'registrarList'}, () => {
              return this.li('Loading...');
            });
          });
          this.h4('Name the depot:');
          this.subview('nameEditor', new TextEditorView({mini: true}));
          this.h4('Depot location:');
          this.div({class: 'depot-location-desc', outlet: 'depotLocationDesc'}, 'placeholderText');
          this.subview('locationEditor', new TextEditorView({mini: true}));
          this.h4('Options');
          this.div({class: 'depotOptions', outlet: 'depotOptions'});
          return this.div({class: 'actions'}, () => {
            this.div({class: 'btn-group'}, () => {
              this.button({outlet: 'cancelButton', class: 'btn'}, 'Cancel');
              return this.button({outlet: 'addButton', tabindex: 100, class: 'btn btn-primary icon icon-rocket'},
                'Add Depot');
            });
            return this.span({class: 'loading loading-spinner-tiny'});
          });
        });
      }
      initialize(param) {
        if (param == null) { param = {}; }
        const {cb} = param;
        this.cb = cb;
        atom.keymaps.add('add-depot-keymap', {
          '.pros-add-depot': {
            'escape': 'core:cancel'
          }
        }
        );
        atom.commands.add(this.element, 'core:cancel', () => this.cancel());
        if (this.panel == null) { this.panel = atom.workspace.addModalPanel({item: this, visible: false}); }

        this.cancelButton.click(() => this.cancel());

        const updateDisable = () => {
          if (!!!this.nameEditor.getText()) {
            return this.addButton.prop('disabled', true);
          } else if (!!!this.locationEditor.getText()) {
            return this.addButton.prop('disabled', true);
          } else if (!this.selectedRegistrar) {
            return this.addButton.prop('disabled', true);
          } else {
            return this.addButton.prop('disabled', false);
          }
        };

        cli.execute({
          cmd: ['pros', 'conduct', 'ls-registrars', '--machine-output'],
          cb: (c, o, e) => {
            let registrars;
            this.registrarList.empty();
            if (c !== 0) {
              std.addMessage(this.registrarList,
              `Error getting list of registars.<br/>STDOUT:<br/>${o}<br/><br/>ERR:</br>${e}`,
              {error: true});
              return;
            }
            try {
              registrars = JSON.parse(o);
            } catch (error1) {
              const error = error1;
              std.addMessage(this.registrarList,
              `Error parsing the list of registrars.<br/>Exception:${error}`,
              {error: true});
              return;
            }
            for (let key of Object.keys(registrars || {})) {
              const value = registrars[key];
              this.registrarList.append(`<li>${key}</li>`);
            }
            return this.registrarList.children().first().click();
          }
        });

        this.on('click', '.registrar-picker li', e => {
          if (this.selectedRegistrar != null) {
            this.selectedRegistrar.removeClass('select');
          }
          this.selectedRegistrar = $(e.target.closest('li'));
          this.selectedRegistrar.addClass('select');
          this.depotConfig = {};
          std.createDepotConfig(this.depotOptions, this.updateDepotConfig, {registrar: this.selectedRegistrar.text()});
          return this.depotLocationDesc.text((std.getDepotConfig(this.selectedRegistrar.text())).location_desc);
        });


        this.addButton.click(() => {
          console.log(this.depotConfig);
          return cli.execute({
            cmd: ['pros', 'conduct', 'add-depot',
            '--name', this.nameEditor.getText(), '--registrar', this.selectedRegistrar.text(),
            '--location', this.locationEditor.getText(), '--no-configure', '--options', JSON.stringify(this.depotConfig)],
            cb: (c, o, e) => {
              if (c !== 0) {
                return atom.notifications.addError('Error adding new PROS depot', {
                  detail: `OUT:\n${o}\n\nERR:\n${e}`,
                  dismissable: true
                }
                );
              } else {
                atom.notifications.addSuccess(`Added ${this.nameEditor.getText()} as a PROS depot`);
                return this.cancel(true);
              }
            }
          });
      });
        this.nameEditor.getModel().onDidChange(() => updateDisable());
        this.locationEditor.getModel().onDidChange(() => updateDisable());
        updateDisable();
        this.panel.show();
        return this.nameEditor.focus();
      }

      updateDepotConfig(depot, key, value) {
        return this.depotConfig[key] = value;
      }

      cancel(complete) {
        if (complete == null) { complete = false; }
        if (this.panel != null) {
          this.panel.hide();
        }
        if (this.panel != null) {
          this.panel.destroy();
        }
        this.panel = null;
        atom.workspace.getActivePane().activate();
        return (typeof this.cb === 'function' ? this.cb({complete, name: this.nameEditor.getText()}) : undefined);
      }
    };
    AddDepotModal.initClass();
    return AddDepotModal;
  })());
