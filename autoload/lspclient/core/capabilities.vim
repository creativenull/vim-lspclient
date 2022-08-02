vim9script

import './types.vim'

const DiagnosticTag = types.DiagnosticTag
const PositionEncodingKind = types.PositionEncodingKind

export def Make(partialCapabilities = null_dict): dict<any>
  const defaults = {
    workspace: {
      didChangeConfiguration: { dynamicRegistration: true },
      configuration: true,
      workspaceFolders: {
        supported: true,
        changeNotifications: false,
      },
    },
    textDocument: {
      synchronization: {
        dynamicRegistration: false,
        willSave: true,
        willSaveWaitUntil: true,
        didSave: true,
      },
      declaration: {
        dynamicRegistration: true,
        linkSupport: true,
      },
      definition: {
        dynamicRegistration: true,
        linkSupport: true,
      },
      publishDiagnostics: {
        relatedInformation: true,
        tagSupport: { valueSet: [DiagnosticTag.Unnecessary, DiagnosticTag.Deprecated] },
        versionSupport: true,
        codeDescriptionSupport: true,
        dataSupport: true,
      },
      diagnostic: {
        dynamicRegistration: true,
        relatedDocumentSupport: true,
      },
    },
    window: {
      workDoneProgress: true,
      showMessage: {
        messageActionItem: { additionalPropertiesSupport: true },
      },
    },
    general: { positionEncodings: [PositionEncodingKind.UTF8, PositionEncodingKind.UTF16] },
  }

  if partialCapabilities->empty()
    return defaults
  endif

  return defaults->extendnew(partialCapabilities)
enddef
