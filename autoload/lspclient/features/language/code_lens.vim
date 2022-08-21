vim9script

import '../../core/protocol.vim'
import '../../fs.vim'
import '../../logger.vim'
import '../../random.vim'
import '../../vim/popup.vim'

const method = 'textDocument/codeLens'

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

  # WIP: Going to have to re-think how to implement once
  # workspace/executeCommand is finished
  # ---

  const buf = bufnr()
  var qfList = []
  for lens in result
    const lineNum = lens.range.start.line + 1
    const virtCol = lens.range.start.character + 1
    const col = buf->getbufline(lineNum)[0]->byteidx(virtCol)

    var text = ''
    if lens->has_key('command')
      text = printf('%s [%s] NOT IMPLEMENTED', lens.command.title, lens.command.command)
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
    title: 'CodeLens',
    items: qfList,
  })

  execute printf('copen %d', listSize > 10 ? 10 : listSize)
enddef

export def Request(ch: channel, buf: number, context: dict<any>): void
  popupLoadingRef = context->get('popupLoadingRef', {})
  const params = {
    textDocument: { uri: fs.BufferToUri(buf) },
    # workDoneToken: random.RandomStr(),
    # partialResultToken: random.RandomStr(),
  }

  protocol.RequestAsync(ch, method, params, OnResponse)
  logger.LogDebug(printf('Request `%s`: %s', method, params->string()))
enddef

def OnResolveResponse(ch: channel, response: dict<any>): void
  logger.LogDebug(printf('Got Response `codeLens/resolve`: %s', response->string()))
enddef

export def ResolveRequest(ch: channel, codeLens: dict<any>, context: dict<any>): void
  const params = codeLens
  protocol.RequestAsync(ch, 'codeLens/resolve', params, OnResolveResponse)
  logger.LogDebug(printf('Request `codeLens/resolve`: %s', params->string()))
enddef
