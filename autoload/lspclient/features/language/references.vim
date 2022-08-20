vim9script

import '../../core/protocol.vim'
import '../../fs.vim'
import '../../logger.vim'
import '../../random.vim'
import '../../vim/popup.vim'

const method = 'textDocument/references'

var popupLoadingRef = {}

def MoveCursorInBuffer(filepath: string, lnum: number, col: number): void
  execute printf("edit +call\\ setcursorcharpos(%d,\\ %d) %s", lnum, col, filepath)
enddef

# Get the file path relative to the project root
def RelativeFilepath(filepath: string): string
  return substitute(filepath, fs.GetProjectRoot('/'), '', '')
enddef

# Handle Location type result
def GoToLocation(location: dict<any>): void
  const filepath = RelativeFilepath(fs.UriToFile(location.uri))
  const lnum = location.range.start.line + 1
  const col = location.range.start.character + 1

  MoveCursorInBuffer(filepath, lnum, col)
enddef

def OnResponse(ch: channel, response: any): void
  logger.LogDebug(printf('Got Response `%s`: %s', method, response->string()))

  # Clear loading window
  if !popupLoadingRef->empty()
    popup.LoadingStop(popupLoadingRef)
  endif

  # Process results
  const result = response->get('result', {})

  if result->empty()
    return
  endif

  if result->type() == v:t_list && !result->empty()
    if result->len() == 1
      const [location] = result
      GoToLocation(location)
    else
      # Show a list of possible files with the same definition
      # Preferebly in a quickfix list
      var refLoclist = []

      for location in result
        var locItem = {}
        const filename = RelativeFilepath(fs.UriToFile(location.uri))
        var buf = filename->bufnr()
        const lnum = location.range.start.line + 1
        var text = ''

        if buf->bufloaded()
          buf = filename->bufnr()
          text = buf->getbufline(lnum)[0]->trim()
        else
          # If refs are in different files
          # ensure their relevant buffers are loaded
          buf = filename->bufadd()
          buf->bufload()
          text = buf->getbufline(lnum)[0]->trim()
        endif

        const virtcol = location.range.start.character + 1
        const col = buf->getbufline(lnum)[0]->byteidx(virtcol)

        locItem.filename = filename
        locItem.lnum = lnum
        locItem.vcol = 0
        locItem.col = col
        locItem.text = text
        locItem.valid = false

        refLoclist->add(locItem->extendnew({ valid: false }))
      endfor

      # Set and open the loclist
      setloclist(0, [], 'r')
      setloclist(0, [], 'a', {
        title: 'References',
        items: refLoclist,
      })

      const listSize = refLoclist->len()
      if listSize == 0
        return
      endif

      execute printf('lopen %d', listSize > 10 ? 10 : listSize)
    endif
  endif
enddef

export def Request(ch: channel, buf: number, context: dict<any>): void
  popupLoadingRef = context->get('popupLoadingRef', {})
  const winId = bufwinid(buf)
  const [_, line, col, _, _] = getcurpos(winId)
  const params = {
    textDocument: { uri: fs.BufferToUri(buf) },
    context: { includeDeclaration: false },
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
