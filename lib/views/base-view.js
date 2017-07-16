/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let BaseView;
const fs = require('fs');
const path = require('path');

module.exports = {
  BaseView: (BaseView = (function() {
    BaseView = class BaseView {
      static initClass() {
        this.prototype.panel = null;
      }

      constructor(file) {
        if (file == null) { file = __dirname; }
        const content = fs.readFileSync(path.join(file, 'view.html'));
        const parser = new DOMParser;
        this.element = (parser.parseFromString(content, 'text/html'))
        .querySelector('div');
      }

      toggle() {
        if ((this.panel != null ? this.panel.isVisible() : undefined)) {
          return this.hide();
        } else {
          return this.show();
        }
      }

      show() {
        if (this.panel == null) { this.panel = atom.workspace.addModalPanel({item: this}); }
        return this.panel.show();
      }

      hide() {
        return (this.panel != null ? this.panel.hide() : undefined);
      }

      isVisible() {
        return (this.panel != null ? this.panel.isVisible() : undefined);
      }

      // A static method to register
      static register() {
        return atom.views.addViewProvider(this, function(m) {
          if (!(m instanceof this)) {
            m = new (this);
          }
          return m.element;
        });
      }
    };
    BaseView.initClass();
    return BaseView;
  })())
};
