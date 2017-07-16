'use babel';
/** @jsx etch.dom */

const brand = require('./brand');
const cli = require('../proscli');
const std = require('./standard');

const etch = require('etch');
const semver = require('semver');
const shell = require('shell');

module.exports = class WelcomeView {
    constructor() {
        etch.initialize(this);
    }
    update() {
        return etch.update(this);
    }
    getTitle() {
        return 'PROS Welcome';
    }
    render() {
        return (
            <div class="pros-welcome">
                <div class="container">
                    <header class="header">
                        {brand.tuxFullColor}
                        {brand.text}
                        <h1 class="title">
                            Open Source C Development for the VEX Cortex
                        </h1>
                    </header>
                    <section class="cli-update">
                        // TODO
                    </section>
                    <section class="panel">
                        <p>For help, please visit:</p>
                        <ul>
                            <li>
                                <a>This page</a> for a guide to getting started with PROS for Atom.
                            </li>
                            <li>
                                The <a>PROS tutorial page</a> to learn about using everything from analog sensors to tasks and multithreading in PROS.
                            </li>
                            <li>
                                The <a>PROS API documentation</a>.
                            </li>
                        </ul>
                        <div class="welcome-settings">
                            <form>
                                <label>
                                    <input type="checkbox" class="input-checkbox" id="pros-welcome-on-startup"/>
                                    Show Welcome for PROS when opening Atom
                                </label>
                                <br/>
                                <label>
                                    <input type="checkbox" class="input-checkbox" id="pros-ga-enabled"/>
                                    Send anonymous usage statistics
                                </label>
                            </form>
                        </div>
                        <div class="versions">
                            <div>
                                <div class="block">
                                    <span>CLI</span>
                                    <span class="badge badge-flexible">
                                        <span class="loading loading-spinner-tiny inline-block" style="margin: auto"></span>
                                    </span>
                                </div>
                                <div class="block">
                                    <span>Plugin</span>
                                    <span class="badge badge-flexible">
                                        <span class="loading loading-spinner-tiny inline-block"></span>
                                    </span>
                                </div>
                            </div>
                        </div>
                    </section>
                    <footer class="footer">
                        <a>pros.cs.purdue.edu</a>
                        <span class="text-subtle">x</span>
                        <a class="icon icon-octoface"></a>
                    </footer>
                </div>
            </div>
        );
    }
};
