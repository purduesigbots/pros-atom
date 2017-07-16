/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS203: Remove `|| {}` from converted for-own loops
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const {$, TextEditorView} = require('atom-space-pen-views');
const cli = require('../proscli');

const hideChildren = element => element.children().not(element.children(':header')).not(element.children('.header')).css('display', 'none');

const showChildren = element => element.children().not(element.children(':header')).not(element.children('.header')).css('display', '');

const fillDepotConfig = null;

module.exports = {
    errorPresenter(settings) {
        return this.div(Object.assign(settings, {class: 'error-presenter'}), () => {
            this.ul({class: 'background-message error-messages'}, () => this.raw('Error!'));
            return this.div();
        });
    },

    applyLoading(element) {
        if (!element.hasClass('loading')) {
            element.addClass('loading');
            hideChildren(element);
            const loading = element.append('<span class=\'loading loading-spinner-medium\'></span>');
            return loading.css('margin', '0 auto');
        }
    },

    removeLoading(element) {
        element.removeClass('loading');
        element.children('span.loading.loading-spinner-medium').remove();
        return showChildren(element);
    },

    addMessage(element, message, settings) {
        if (settings == null) { settings = {}; }
        if (!(settings != null ? settings.nohide : undefined)) { hideChildren(element); }
        const div = $('<div></div>');
        element.append(div);
        div.addClass('pros-message');
        if (settings != null ? settings.error : undefined) {
            div.addClass('error-presenter');
            div.append('<ul class="background-message error-messages">Error!</ul>');
        }
        div.append(message);
        const subscription = atom.tooltips.add(div, {title: 'Copy Text'});
        div.click(() => atom.clipboard.write(div.text()));
        return subscription;
    },

    clearMessages(element) {
        element.children('.pros-message').remove();
        return showChildren(element);
    },

    getDepotConfig(registrar) {
        if (!this.depotConfigCache) { this.depotConfigCache = {}; }
        if (!this.depotConfigCache.hasOwnProperty(registrar)) { this.updateCache(registrar); }
        return this.depotConfigCache[registrar];
    },

    updateCache(registrar) {
        return cli.execute({
            cmd: ['pros', 'conduct', 'ls-registrars', '--machine-output'],
            cb: (c, o, e) => {
                if (c === 0) {
                    try {
                        Object.assign(this.depotConfigCache, JSON.parse(o));
                        if (this.depotConfigCache.hasOwnProperty(registrar)) {
                            this.fillDepotConfig(this.depotConfigCache[registrar].config);
                        }
                        return console.log(this.depotConfigCache);
                    } catch (err) {
                        return console.error(err);
                    }
                } else { return console.log({c, o, e}); }
            }
        });
    },

    createDepotConfig(target, updateConfig, {name: depot, registrar}) {
        if (!target) { target = $('<div></div'); }
        if (!this.depotConfigCache) { this.depotConfigCache = {}; }
        this.applyLoading(target);
        const createBoolParameter = function(key, prop, value) {
            let left;
            const label = $('<label class=\'depot-input\'></label>');
            label.addClass('input-label');
            label.data('key', key);
            const input = $(`<input data-key='${key}' class='input-checkbox' type='checkbox'> \
${prop.prompt} \
</input>`);
            input.click(() => updateConfig(depot, key, input.is(':checked')));
            input.attr('checked', (left = value != null ? value : prop.default) != null ? left : false);
            label.append(input);
            return label;
        };
        const createStrParameter = function(key, prop, value) {
            const div = $(`<div data-key='${key}' class='depot-input'>${prop.prompt}</div>`);
            const editor = new TextEditorView({mini: true, placeholderText: prop.default});
            if (value) { editor.getModel().setText(value); }
            editor.getModel().onDidChange(() => updateConfig(depot, key, editor.getModel().getText()));
            return div.append(editor);
        };
        this.fillDepotConfig = config => {
            return cli.execute({
                cmd: ['pros', 'conduct', 'info-depot', depot, '--machine-output'],
                cb: (c, o, e) => {
                    let k, v;
                    this.removeLoading(target);
                    if (c === 0) {
                        let settings = {};
                        try {
                            settings = JSON.parse(o);
                        } catch (err) {
                            this.addMessage(target,
                                `There was an error parsing the configuration: ${o} (${err})`,
                                {error: true});
                            return;
                        }
                        target.empty();
                        const keys = ((() => {
                            const result = [];
                            for (k of Object.keys(config || {})) {
                                v = config[k];
                                result.push(k);
                            }
                            return result;
                        })()).sort();
                        return (() => {
                            const result1 = [];
                            for ({k, v} of Array.from(((() => {
                                const result2 = [];
                                for (k of Array.from(keys)) {                 result2.push({k, v: config[k]});
                                }
                                return result2;
                            })()))) {
                                if (v.method === 'bool') {
                                    result1.push(target.append(createBoolParameter(k, v, settings[k])));
                                } else {
                                    result1.push(target.append(createStrParameter(k, v, settings[k])));
                                }
                            }
                            return result1;
                        })();
                    } else {
                        return this.addMessage(this.selectedDepotConfig,
                            `There was an error retrieving the depot configuration: \
<br/>STDOUT:<br/>${o}<br/><br/>ERR:<br/>${e}`
                        );
                    }
                }
            });
        };
        if (!this.depotConfigCache.hasOwnProperty(registrar)) {
            return this.updateCache(registrar);
        } else {
            return this.fillDepotConfig(this.depotConfigCache[registrar].config);
        }
    }
};
