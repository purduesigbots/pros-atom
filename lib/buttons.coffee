module.exports =
  addButtons: (toolBar) ->
    toolBar.addButton {
      icon: 'upload',
      callback: 'PROS:Upload-Project'
      tooltip: 'Upload PROS project',
      iconset: 'fi'
    }
    toolBar.addButton {
      icon: 'circuit-board',
      callback: 'PROS:Toggle-Terminal',
      tooltip: 'Open cortex serial output'
    }
    # add pros-specific buttons before spacer for optimal UX
    toolBar.addSpacer()
