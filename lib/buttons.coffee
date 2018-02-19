module.exports =
  addButtons: (toolBar) ->
    toolBar.addSpacer priority: 50
    toolBar.addButton {
      icon: 'upload',
      callback: 'PROS:Upload-Project'
      tooltip: 'Upload PROS project',
      iconset: 'fi',
      priority: 50
    }
    toolBar.addButton {
      icon: 'wrench',
      callback: 'PROS:Make-Project',
      tooltip: 'Build PROS project',
      iconset: 'fi',
      priority: 50
    }
    toolBar.addButton {
      icon: 'circuit-board',
      callback: 'PROS:Toggle-Terminal',
      tooltip: 'Open cortex serial output',
      priority: 50
    }
    # add pros-specific buttons before spacer for optimal UX
    toolBar.addSpacer priority: 50
