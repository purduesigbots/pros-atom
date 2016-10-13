module.exports =
  addButtons: (toolBar) ->
    toolBar.addButton {
      icon: 'upload',
      callback: 'PROS:Upload-Project'
      tooltip: 'Upload PROS project',
      iconset: 'fi',
      priority: 0
    }
    toolBar.addButton {
      icon: 'eye-slash',
      callback: 'PROS:Toggle-Terminal',
      tooltip: 'Toggle PROS terminal output visibility',
      iconset: 'fa',
      priority: 0
    }
    toolBar.addButton {
      icon: 'circuit-board',
      callback: 'PROS:Open-Cortex',
      tooltip: 'Open cortex serial output'
    }

    # separate power button from the rest of the toolbar to reduce likelihood of
    # it being hit by accident
    # (inb4 angry user report)
    toolBar.addSpacer priority: 0
    toolBar.addButton {
      icon: 'power',
      callback: 'PROS:Toggle-PROS',
      tooltip: 'Toggle PROS functionality',
      iconset: 'fi',
      priority: 0
    }
    # add pros-specific buttons before spacer for optimal UX
    toolBar.addSpacer priority: 0
