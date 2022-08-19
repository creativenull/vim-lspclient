vim9script

import '../../core/protocol.vim'
import '../../fs.vim'
import '../../logger.vim'
import '../../random.vim'
import '../../vim/popup.vim'

const method = 'textDocument/documentHighlight'

var popupLoadingRef = {}

def OnResponse(ch: channel, response: any): void
  logger.LogDebug(printf('Got Response `%s`: %s', method, response->string()))

  # Clear loading window
  if !popupLoadingRef->empty()
    popup.LoadingStop(popupLoadingRef)
  endif

  # WIP: Implementation
enddef

export def Request(ch: channel, buf: number, context: dict<any>): void
  popupLoadingRef = context->get('popupLoadingRef', {})
  const winId = bufwinid(buf)
  const [_, line, col, _, _] = getcurpos(winId)
  const params = {
    textDocument: { uri: fs.BufferToUri(buf) },
    position: {
      line: line - 1,
      character: col - 1,
    },
    workDoneToken: random.RandomStr(),
    # partialResultToken: '',
  }

  protocol.RequestAsync(ch, method, params, OnResponse)
  logger.LogDebug(printf('Request `%s`: %s', method, params->string()))
enddef
