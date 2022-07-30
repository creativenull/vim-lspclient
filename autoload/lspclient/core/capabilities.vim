vim9script

export def Make(partialCapabilities = null_dict): dict<any>
  const defaults = {
    workspace: {
      applyEdit: true,
      didChangeConfiguration: {
        dynamicRegistration: false,
      },
      configuration: true,
    },
    textDocument: {
      synchronization: {
        dynamicRegistration: false,
        willSave: true,
        willSaveWaitUntil: true,
        didSave: true,
      },
    },
    window: {
      workDoneProgress: true,
      showMessage: {
        messageActionItem: {
          additionalPropertiesSupport: true,
        },
      },
    },
  }

  if partialCapabilities->empty()
    return defaults
  endif

  return defaults->extendnew(partialCapabilities)
enddef
