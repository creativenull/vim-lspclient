vim9script

import './types.vim'

const DiagnosticTag = types.DiagnosticTag
const PositionEncodingKind = types.PositionEncodingKind
const SymbolKind = types.SymbolKind
const SymbolTag = types.SymbolTag
const FoldingRangeKind = types.FoldingRangeKind

export def Make(partialCapabilities = null_dict): dict<any>
  const defaults = {
    workspace: {
      didChangeConfiguration: { dynamicRegistration: true },
      configuration: true,
      workspaceFolders: true,
    },
    textDocument: {
      synchronization: {
        dynamicRegistration: false,
        willSave: true,
        willSaveWaitUntil: true,
        didSave: true,
      },
      declaration: {
        dynamicRegistration: false,
        linkSupport: true,
      },
      definition: {
        dynamicRegistration: false,
        linkSupport: true,
      },
      typeDefinition: {
        dynamicRegistration: false,
        linkSupport: true,
      },
      implementation: {
        dynamicRegistration: false,
        linkSupport: true,
      },
      references: { dynamicRegistration: false },
      documentHighlight: { dynamicRegistration: false },
      hover: {
        dynamicRegistration: false,
        contentFormat: ['plaintext'],
      },
      codeLens: { dynamicRegistration: false },
      documentSymbol: {
        dynamicRegistration: false,
        hierarchicalDocumentSymbolSupport: true,
        # All symbol kinds
        symbolKind: { valueSet: SymbolKind->keys()->mapnew((i, kind) => SymbolKind[kind]) },
        tagSupport: { valueSet: [SymbolTag.Deprecated] },
        labelSupport: true,
      },
      foldingRange: {
        dynamicRegistration: false,
        rangeLimit: 100,
        lineFoldingOnly: true,
        foldingRangeKind: { valueSet: FoldingRangeKind->keys()->mapnew((i, kind) => FoldingRangeKind[kind]) },
        foldingRange: { collapsedText: true },
      },
      publishDiagnostics: {
        relatedInformation: true,
        tagSupport: { valueSet: [DiagnosticTag.Unnecessary, DiagnosticTag.Deprecated] },
        versionSupport: true,
        codeDescriptionSupport: true,
        dataSupport: true,
      },
    },
    window: {
      workDoneProgress: true,
      showMessage: {
        messageActionItem: { additionalPropertiesSupport: true },
      },
    },
  }

  if partialCapabilities->empty()
    return defaults
  endif

  return defaults->extendnew(partialCapabilities)
enddef
