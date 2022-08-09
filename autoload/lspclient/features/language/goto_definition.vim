vim9script

import '../../logger.vim'
import '../../fs.vim'
import '../../core/protocol.vim'

def OnResponse(ch: channel, response: any): void
  logger.LogDebug('Response `textDocument/definition`: ' .. response->string())
enddef

def MakeRequest(ch: channel, params: dict<any>): void
  protocol.RequestAsync(ch, 'textDocument/definition', params, OnResponse)
  logger.LogDebug('Request `textDocument/definition`: ' .. params->string())
enddef

export def Request(ch: channel, buf: number): void
  const curpos = getcurpos()
  const line = curpos[1]
  const col = curpos[2]
  const params = {
    textDocument: {
      uri: fs.ProjectFileToUri(buf->bufname()),
    },
    position: {
      line: line - 1,
      character: col - 1,
    },
    # workDoneToken: '',
    # partialResultToken: '',
  }

  MakeRequest(ch, params)
enddef

export def Register(ch: channel, registrationOptions: any, lspClientConfig: dict<any>): void
  logger.LogDebug('Received Dynamic Registration `textDocument/definition`: ' .. registrationOptions->string())
enddef
