vim9script

import '../../logger.vim'
import '../../fs.vim'
import '../../core/protocol.vim'

var isDynamicallyEnabled = false

def OnGotoDeclarationReponse(): void

enddef

export def RequestGotoDeclaration(ch: channel, document: dict<any>): void
  if isDynamicallyEnabled
    const params = {
      textDocument: { uri: document.uri },
      position: {
        line: document.cursor.line - 1,
        character: document.cursor.col - 1,
      },
      workDoneToken: '',
      partialResultToken: '',
    }
    # protocol.RequestAsync(ch, 'textDocument/declaration', params, OnGotoDeclarationReponse)
    logger.LogInfo('Request textDocument/declaration: ' .. params->string())
  endif
enddef

export def HandleGotoDeclarationRegistration(ch: channel, registrationOptions: any, lspClientConfig: dict<any>): void
  logger.LogInfo('Received Dynamic Registration: textDocument/declaration: ' .. registrationOptions->string())
enddef
