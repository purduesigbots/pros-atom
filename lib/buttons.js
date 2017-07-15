/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
module.exports = {
    addButtons(toolBar) {
        toolBar.addSpacer({priority: 50});
        toolBar.addButton({
            icon: 'upload',
            callback: 'PROS:Upload-Project',
            tooltip: 'Upload PROS project',
            iconset: 'fi',
            priority: 50
        });
        toolBar.addButton({
            icon: 'circuit-board',
            callback: 'PROS:Toggle-Terminal',
            tooltip: 'Open cortex serial output',
            priority: 50
        });
        // add pros-specific buttons before spacer for optimal UX
        return toolBar.addSpacer({priority: 50});
    }
};
