vim9script

import '../../core/protocol.vim'
import '../../fs.vim'
import '../../logger.vim'
import '../../random.vim'
import '../../vim/popup.vim'
import '../workspace/common/text_edit.vim'

const method = 'textDocument/formatting'
var popupLoadingRef = {}

def OnResponse(ch: channel, buf: number, response: dict<any>): void
  logger.LogDebug(printf('Got Response `%s`: %s', method, response->json_encode()))

  # Clear loading window
  if !popupLoadingRef->empty()
    popup.LoadingStop(popupLoadingRef)
  endif

  const result = response->get('result', [])

  if result->empty()
    return
  endif

  # WIP: Implementation
  text_edit.ApplyBufTextEdits(buf, result)
enddef

export def Request(ch: channel, buf: number, context: dict<any>): void
  popupLoadingRef = context->get('popupLoadingRef', {})
  var params = {
    textDocument: { uri: fs.BufferToUri(buf) },
    options: {},
  }

  if buf->getbufvar('&tabstop') != buf->getbufvar('&softtabstop')
    params.options.tabSize = buf->getbufvar('&softtabstop')
  elseif buf->getbufvar('&tabstop') == buf->getbufvar('&softtabstop')
    params.options.tabSize = buf->getbufvar('&tabstop')
  else
    params.options.tabSize = 4
  endif

  params.options.insertSpaces = buf->getbufvar('&expandtab') ? true : false

  protocol.RequestAsync(ch, method, params, (lspChannel: channel, response: dict<any>) => {
    OnResponse(lspChannel, buf, response)
  })
  logger.LogDebug(printf('Request `%s`: %s', method, params->string()))
enddef
