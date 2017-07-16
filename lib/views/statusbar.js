/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const {CompositeDisposable} = require('atom');
const {$, View} = require('atom-space-pen-views');
const cli = require('../proscli');

class StatusBar extends View {
  static initClass() {
        // coffeelint: enable=max_line_length
  
    this.prototype.tooltip = null;
  
    this.prototype.count = 0;
  }
  static content() {
    return this.div({class: 'pros-status-bar inline-block'}, () => {
      // coffeelint: disable=max_line_length
      return this.button({class: 'btn btn-default', outlet: 'button'},
        () => this.raw(`<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\"> \
<defs> \
<g id=\"logo\"> \
<polygon points=\"79 41.4 94.2 54.5 50.1 93 50.1 93 50 93 6.1 54.8 21.3 41.5 50.1 83.7 \"/> \
<polygon points=\"28.2 28.2 29 29.7 71.3 29.7 72.1 28.2\"/> \
<polygon points=\"38.1 56.5 33.1 42 18.9 34.1 \"/> \
<polygon points=\"62.2 56.7 67.3 42 81.2 34.3 \"/> \
<path d=\"M50.1 8.6L12.8 25.5h13.4l2.8 4.3H71.3l2.8-4.3H87.5L50.1 8.6zM53.1 18.9l-2.9 1.5 -2.9-1.5v-2.9l2.9-1.5 2.9 1.5V18.9z\"/> \
<path d=\"M80.5 34.1H19.8l0.1 0.1 18.5 2.8 -0.3 19.5 -2.4-2.8L49.4 70.6V52.3c0-0.3 0.3-0.6 0.6-0.6h0.3c0.3 0 0.6 0.3 0.6 0.6V70.6L62.2 56.6l-0.1 0.1 -0.3-19.6 18.4-2.6L80.5 34.1zM50.1 48.8c-0.6 0-1.2-0.5-1.2-1.2 0-0.6 0.5-1.2 1.2-1.2 0.6 0 1.2 0.5 1.2 1.2C51.3 48.2 50.8 48.8 50.1 48.8zM50.1 43.8c-0.6 0-1.2-0.5-1.2-1.2 0-0.6 0.5-1.2 1.2-1.2 0.6 0 1.2 0.5 1.2 1.2C51.3 43.3 50.8 43.8 50.1 43.8zM50.1 38.7c-0.6 0-1.2-0.5-1.2-1.2s0.5-1.2 1.2-1.2c0.6 0 1.2 0.5 1.2 1.2S50.8 38.7 50.1 38.7z\"/> \
</g> \
</defs> \
<use xlink:href=\"#logo\"/> \
<g id='overlay'><use xlink:href='#logo'/></g> \
</svg>`
        )
      );
    });
  }
  initialize() {
    if (!atom.config.get('pros.enable')) {
      this.button.addClass('disable');
      this.updateTooltip();
    }

    this.button.on('click', () => {
      if (this.button.hasClass('has-update')) {
        return atom.workspace.open('pros://welcome');
      } else {
        return atom.commands.dispatch(atom.views.getView(atom.workspace.getActivePane()), 'PROS:Toggle-PROS');
      }
    });

    return atom.config.onDidChange('pros.enable', ({newValue, oldValue}) => {
      if (newValue) {
        this.button.removeClass('disable');
        return this.updateTooltip();
      } else {
        this.button.addClass('disable');
        return this.updateTooltip();
      }
    });
  }

  attach(provider) { return provider.addRightTile({item: this, priority: -10}); }

  updateTooltip() {
    let tip = '';
    if (this.button.hasClass('animate')) {
      tip = 'Running PROS CLI tasks in in the background.<br/>';
    }
    if (this.button.hasClass('has-update')) {
      tip += 'Click to update the PROS CLI.';
    } else if (this.button.hasClass('disable')) {
      tip += 'Click to enable PROS editor components.';
    } else {
      tip += 'Click to disable PROS editor components.';
    }
    if (this.tooltip != null) {
      this.tooltip.dispose();
    }
    return this.tooltip = atom.tooltips.add(this.button, {title: tip});
  }
  working() {
    if (this.count === 0) {
      this.button.addClass('animate');
      this.updateTooltip();
    }
    return this.count += 1;
  }

  stop(uid) {
    if (uid == null) { uid = 0; }
    this.count -= 1;
    if (this.count === 0) {
      this.button.removeClass('animate');
      return this.updateTooltip();
    }
  }
}
StatusBar.initClass();

module.exports = new StatusBar;
