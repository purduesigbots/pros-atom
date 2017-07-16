/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__
 * DS202: Simplify dynamic range loops
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// scopes for univesal config are: atom, project, directory

const path = require('path');
const fs = require('fs');

const handlers = {
    atom(config, identifier, options) {
        config = module.exports.filterConfig(config, 'atom');
        const obj = {};
        for (let property in config) {
            const value = config[property];
            obj[property] = atom.config.get(`${identifier}.${property}`);
        }
        return obj;
    },

    project(config, identifier, options) {
        config = module.exports.filterConfig(config, 'project');
        let obj = {};
        const editor = atom.workspace.getActiveTextEditor();
        const project = atom.project.relativizePath(editor != null ? editor.getPath() : undefined)[0];
        if (!project) {
            return obj;
        }
        const file = path.join(project, (__guard__(options != null ? options.project : undefined, x => x.filename) || '.atom-config'));
        try {
            fs.accessSync(file, fs.F_OK | fs.R_OK);
        } catch (e) {  // file doesn't exist or some other exception... just ignore
            return obj;
        }
        obj = JSON.parse(fs.readFileSync(file));
        for (let property in obj) {
            const value = obj[property];
            if (!config.hasOwnProperty(property)) {
                delete obj[property];
            }
        }
        return obj;
    },

    directory(config, identifier, options) {
        const cofig = module.exports.filterConfig(config, 'directory');
        let obj = {};
        const filename = __guard__(options != null ? options.directory : undefined, x => x.filename) || '.atom-config';
        if (!atom.workspace.getActiveTextEditor()) { return; }
        let dir = atom.workspace.getActiveTextEditor().getPath();
        for (let i = 1, end = __guard__(options != null ? options.directory : undefined, x1 => x1.recurseTimes) || 5, asc = 1 <= end; asc ? i < end : i > end; asc ? i++ : i--) {
            if (typeof dir !== 'string') {
                break;
            }
            dir = path.dirname(dir);
            try {
                const pat = path.join(dir, filename);
                fs.accessSync(pat, fs.F_OK | fs.R_OK);
                obj = JSON.parse(fs.readFileSync(pat));
                break;
            } catch (e) {
                continue;
            }
        }
        for (let property in obj) {
            const value = obj[property];
            if (!config.hasOwnProperty(property)) {
                delete obj[property];
            }
        }
        return obj;
    }
};

module.exports = {
    addHandler(scope, func) {
        this.handlers[scope] = func;
    },

    loadConfig(config, scopes, identifier, options) {
        if (!scopes) {
            scopes = ['atom', 'project', 'directory'];
        }
        const cfg = {};
        for (let scope of Array.from(scopes)) {
            if (handlers.hasOwnProperty(scope)) {
                const object = handlers[scope](config, identifier, options);
                for (let prop in object) {
                    const value = object[prop];
                    cfg[prop] = value;
                }
            }
        }
        return cfg;
    },

    filterConfig(config, scope) {
        const cfg = {};
        for (let property in config) {
            // if no scope, assume it's there
            const value = config[property];
            if (!value.hasOwnProperty('scope') || (value.scope.indexOf(scope) >= 0)) {
                cfg[property] = value;
                if (value.type === 'object') {
                    cfg[property].properties = arguments.callee(value.properties, scope);
                }
            }
        }
        return cfg;
    }
};

function __guard__(value, transform) {
    return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
