vim9script

import '../../core/protocol.vim'
import '../../fs.vim'
import '../../logger.vim'
import '../../random.vim'
import '../../vim/popup.vim'
import '../../vim/colors.vim'

const method = 'textDocument/documentHighlight'

var popupLoadingRef = {}
var matchedRef: number = -1

def OnResponse(ch: channel, response: any): void
  logger.LogDebug(printf('Got Response `%s`: %s', method, response->string()))

  const result = response->get('result', [])

  if result->empty()
    return
  endif

  # Clear loading window
  if !popupLoadingRef->empty()
    popup.LoadingStop(popupLoadingRef)
  endif

  const buf = bufnr()
  var positions = []

  for documentHighlight in result
    const lineNum = documentHighlight.range.start.line + 1
    const col = documentHighlight.range.start.character + 1
    const byteCol = buf->getbufline(lineNum)[0]->byteidx(col)

    const endLineNum = documentHighlight.range.end.line + 1
    const endCol = documentHighlight.range.end.character + 1
    const endByteCol = buf->getbufline(endLineNum)[0]->byteidx(endCol)

    positions->add([lineNum, byteCol, endByteCol - byteCol])
  endfor

  matchedRef = matchaddpos('LSPClientDocumentHighlight', positions)
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

export def Clear(): void
  if matchedRef != -1
    matchdelete(matchedRef)
    matchedRef = -1
  endif
enddef

export def DefineHighlights(): void
  hlset([
    { name: 'LSPClientDocumentHighlight', guibg: colors.DocumentHighlightBg, guifg: colors.DocumentHighlightFg },
  ])
enddef
