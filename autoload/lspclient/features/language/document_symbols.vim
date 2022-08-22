vim9script

import '../../core/protocol.vim'
import '../../fs.vim'
import '../../logger.vim'
import '../../random.vim'
import '../../vim/popup.vim'

const method = 'textDocument/documentSymbol'

var popupLoadingRef = {}

def OnResponse(ch: channel, response: dict<any>): void
  logger.LogDebug(printf('Got Response `%s`: %s', method, response->string()))

  # Clear loading window
  if !popupLoadingRef->empty()
    popup.LoadingStop(popupLoadingRef)
  endif

  const result = response->get('result', [])
  if result->empty()
    return
  endif

  const buf = bufnr()
  var qfList = []

  for symbol in result
    const lineNum = symbol.range.start.line + 1
    const virtCol = symbol.range.start.character + 1
    const col = buf->getbufline(lineNum)[0]->byteidx(virtCol)

    var text = ''
    if symbol->has_key('detail') && symbol->has_key('name')
      text = printf('%s %s', symbol.name, symbol.detail)
    else
      text = symbol.name
    endif

    qfList->add({
      bufnr: buf,
      valid: false,
      lnum: lineNum,
      col: col,
      text: text,
    })
  endfor

  const listSize = qfList->len()
  if listSize == 0
    return
  endif

  setqflist([], 'r')
  setqflist([], 'a', {
    title: 'Document Symbols',
    items: qfList,
  })

  execute printf('copen %d', listSize > 10 ? 10 : listSize)
enddef

export def Request(ch: channel, buf: number, context: dict<any>): void
  popupLoadingRef = context->get('popupLoadingRef', {})
  const params = {
    textDocument: { uri: fs.BufferToUri(buf) },
  }

  protocol.RequestAsync(ch, method, params, OnResponse)
  logger.LogDebug(printf('Request `%s`: %s', method, params->string()))
enddef
