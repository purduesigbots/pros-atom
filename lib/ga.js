/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let GA;
const querystring = require('querystring');

// RFC1422-compliant Javascript UUID function. Generates a UUID from a random
// number (which means it might not be entirely unique, though it should be
// good enough for many uses). See http://stackoverflow.com/questions/105034
// (from https://gist.github.com/bmc/1893440)
const generateUUID = () =>
    'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        const r = (Math.random() * 16) | 0;
        const v = c === 'x' ? r : ((r & 0x3)|0x8);
        return v.toString(16);
    })
;

const extend = function(target, ...propertyMaps) {
    for (let propertyMap of Array.from(propertyMaps)) {
        for (let key in propertyMap) {
            const value = propertyMap[key];
            target[key] = value;
        }
    }
    return target;
};

module.exports =
  (GA = (function() {
      GA = class GA {
          static initClass() {
  
              this.startSession = () => {
                  if (atom.config.get('pros.googleAnalytics.enabled') && 
             (atom.config.get('core.telemetryConsent') === 'limited')) {
                      if (!atom.config.get('pros.googleAnalytics.cid')) {
                          atom.config.set('pros.googleAnalytics.cid', GA.generateUUID());
                      }
                      return this.sendData();
                  }
              };
          }
          static sendData(sessionControl) {
              if (sessionControl == null) { sessionControl = 'start'; }
              if (!atom.config.get('pros.googleAnalytics.cid')) {
                  atom.config.set('pros.googleAnalytics.cid', GA.generateUUID());
              }
              const params = {
                  v: 1,
                  t: 'event',
                  ec: 'session',
                  ea: `${sessionControl}_session`,
                  tid: 'UA-84548828-2',
                  cid: atom.config.get('pros.googleAnalytics.cid')
              };
              extend(params,
                  {sc: sessionControl});
              return this.post(`https://google-analytics.com/collect?${querystring.stringify(params)}`);
          }

          static post(url) {
              if (!atom.inDevMode()) {
                  const xhr = new XMLHttpRequest();
                  xhr.open('POST', url);
                  return xhr.send(null);
              }
          }

          static generateUUID() {
              return generateUUID();
          }
      };
      GA.initClass();
      return GA;
  })());
