/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * DS208: Avoid top-level this
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// const path = require('path');
// const fs = require('fs');
const {loadConfig} = require('./universal-config');

module.exports = {

    FILENAME: 'pros-atom.json',
    niceName: `pros-atom configuration (${this.FILENAME})`,

    settings(file_path) {
        if (file_path == null) { file_path = atom.workspace.getActiveTextEditor().getPath(); }
        return loadConfig(this.config, null, 'pros', {
            project: {
                filename: 'atom-project.pros'
            },
            directory: {
                filename: 'atom-project.pros',
                recurseTimes: atom.config.get('pros-atom.max_scan_iterations')
            }
        }
        );
    },

    config: {
        enable: {
            type: 'boolean',
            default: true,
            scope: ['atom'],
            description: 'Disables PROS tool-bar buttons, linter, autocomplete, and build'
        },
        override_beautify_provider: {
            type: 'boolean',
            default: true,
            scope: ['atom']
        },
        parallel_make_jobs: {
            type: 'integer',
            default: 1,
            minimum: 1,
            scope: ['atom']
        },
        max_scan_iterations: {
            type: 'integer',
            default: 10,
            minimum: 2
        },
        include_paths: {
            type: 'array',
            default: ['./include'],
            items: {
                type: 'string'
            }
        },
        autocomplete: {
            type: 'object',
            properties: {
                flags: {
                    type: 'array',
                    default: [],
                    items: {
                        type: 'string'
                    }
                },
                includeDocumentation: {
                    type: 'boolean',
                    default: true
                },
                includeNonDoxygenCommentsAsDocumentation: {
                    type: 'boolean',
                    default: 'true'
                }
            }
        },
        googleAnalytics: {
            title: 'Google Analytics',
            type: 'object',
            properties: {
                enabled: {
                    title: 'Enable Google Analytics',
                    description:
          'If set to \'true,\' you help us to understand and better cater to our'+
          'user-base by sending us information about the size, relative geograph'+
          'ic area, and general activities of the people using PROS.',
                    type: 'boolean',
                    default: true
                },
                cid: {
                    title: 'Google Analytics client ID',
                    description:
          'Used when making requests to the GA API. \
Please do not change this value unless you have \'enabled\' set to \'false\'',
                    type: 'string',
                    default: ''
                }
            }
        },
        welcome: {
            title: 'Welcome Page',
            type: 'object',
            properties: {
                enabled: {
                    title: 'Show on startup',
                    type: 'boolean',
                    default: true
                }
            }
        },
        lint: {
            type: 'object',
            properties: {
                default_C_flags: {
                    type: 'string',
                    default: '-Wall'
                },
                default_Cpp_flags: {
                    type: 'string',
                    default: '-Wall -std=c++11'
                },
                error_limit: {
                    type: 'integer',
                    default: 15
                },
                suppress_warnings: {
                    type: 'boolean',
                    default: false
                },
                on_the_fly: {
                    type: 'boolean',
                    default: true
                }
            }
        },
        locale: {
            type: 'string',
            title: 'Locale when running PROS CLI',
            description: 'If the default value isn\'t working, try changing this field to C.UTF-8 '+
                   'or to \'inherit\' to possibly inherit from the system environment.',
            default: 'en_US.UTF-8'
        }
    }
};
