vim9script

import '../../core/protocol.vim'
import '../../fs.vim'
import '../../logger.vim'
import '../../random.vim'

const method = 'textDocument/foldingRange'

def OnResponse(ch: channel, response: dict<any>): void
  logger.LogDebug(printf('Got Response `%s`: %s', method, response->string()))

  const result = response->get('result', [])

  if result->empty()
    return
  endif

  # WIP: Implement this
enddef

export def Request(ch: channel, buf: number, context: dict<any>): void
  const params = {
    textDocument: { uri: fs.BufferToUri(buf) },
    # workDoneToken: random.RandomStr(),
    # partialResultToken: '',
  }

  protocol.RequestAsync(ch, method, params, OnResponse)
  logger.LogDebug(printf('Request `%s`: %s', method, params->string()))
enddef
