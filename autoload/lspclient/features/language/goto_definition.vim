vim9script

import '../../logger.vim'
import '../../fs.vim'
import '../../core/protocol.vim'

def OnGotoDefinitionReponse(ch: channel, response: any): void
  logger.LogInfo('Response textDocument/definition: ' .. response->string())
enddef

export def RequestGotoDefinition(ch: channel, document: dict<any>): void
  const params = {
    textDocument: { uri: document.uri },
    position: document.position,
    # workDoneToken: '',
    # partialResultToken: '',
  }
  protocol.RequestAsync(ch, 'textDocument/definition', params, OnGotoDefinitionReponse)
  logger.LogInfo('Request textDocument/definition: ' .. params->string())
enddef

export def HandleGotoDefinitionRegistration(ch: channel, registrationOptions: any, lspClientConfig: dict<any>): void
  logger.LogInfo('Received Dynamic Registration: textDocument/definition: ' .. registrationOptions->string())
enddef
