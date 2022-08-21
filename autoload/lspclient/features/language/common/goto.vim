vim9script

import '../../../core/protocol.vim'
import '../../../fs.vim'
import '../../../logger.vim'
import '../../../random.vim'
import '../../../vim/popup.vim'

var popupLoadingRef = {}
var requestMethod = ''

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

# Handle LocationLink type result
def GoToLocationLink(location: dict<any>): void
  const filepath = RelativeFilepath(fs.UriToFile(location.targetUri))
  const lnum = location.targetRange.start.line + 1
  const col = location.targetRange.start.character + 1

  MoveCursorInBuffer(filepath, lnum, col)
enddef

def OnResponse(ch: channel, response: any): void
  logger.LogDebug(printf('Got Response `%s`: %s', requestMethod, response->string()))

  # Clear loading window
  if !popupLoadingRef->empty()
    popup.LoadingStop(popupLoadingRef)
  endif

  # Process results
  const result = response->get('result', {})

  if result->empty()
    # Do nothing
    return
  endif

  if result->type() == v:t_dict
    GoToLocation(result)

    return
  endif

  if result->type() == v:t_list
    if result->len() == 1
      const location = result[0]

      # Handle Location or LocationLink
      if !location->get('targetUri', '')->empty()
        GoToLocationLink(location)
      else
        GoToLocation(location)
      endif
    else
      # WIP
      # Show a list of possible files with the same definition
      # Preferebly in a quickfix list
      var qlist = []

      for location in result
        var qfItem = {}
        var filename = ''
        var lnum = -1
        var virtcol = -1
        var col = -1

        # Handle Location or LocationLink
        if location->get('targetUri', '')->empty()
          filename = RelativeFilepath(fs.UriToFile(location.uri))
          lnum = location.range.start.line + 1
          virtcol = location.range.start.character + 1
          col = virtcol2col(0, lnum, virtcol)
        else
          filename = RelativeFilepath(fs.UriToFile(location.targetUri))
          lnum = location.targetRange.start.line + 1
          virtcol = location.targetRange.start.character + 1
          col = virtcol2col(0, lnum, virtcol)
        endif

        qfItem.filename = filename
        qfItem.lnum = lnum
        qfItem.vcol = 0
        qfItem.col = col
        qfItem.valid = true

        qlist->add(qfItem->extendnew({ valid: false }))
      endfor

      # Show the qf list
      setqflist(qlist, 'r')
    endif
  endif
enddef

def MakeRequest(ch: channel, method: string, params: dict<any>): void
  protocol.RequestAsync(ch, method, params, OnResponse)
  logger.LogDebug(printf('Request `%s`: %s', method, params->string()))
enddef

export def Request(ch: channel, method: string, buf: number, context: dict<any>): void
  popupLoadingRef = context->get('popupLoadingRef', {})
  requestMethod = method
  const winId = bufwinid(buf)
  const curpos = getcurpos(winId)
  const line = curpos[1]
  const col = curpos[2]
  const params = {
    textDocument: { uri: fs.BufferToUri(buf) },
    position: {
      line: line - 1,
      character: col - 1,
    },
    # workDoneToken: random.RandomStr(),
    # partialResultToken: '',
  }

  MakeRequest(ch, method, params)
enddef

export def Register(ch: channel, method: string, registrationOptions: any, lspClientConfig: dict<any>): void
  logger.LogDebug(printf('Received Dynamic Registration `%s`: %s', method, registrationOptions->string()))
enddef
