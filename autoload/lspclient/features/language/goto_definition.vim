vim9script

import '../../core/protocol.vim'
import '../../fs.vim'
import '../../logger.vim'
import '../../random.vim'

# Get the file path relative to the project root
def RelativeFilepath(filepath: string): string
  return substitute(filepath, fs.GetProjectRoot('/'), '', '')
enddef

# Handle Location type result
def GoToLocation(location: dict<any>): void
  const filepath = RelativeFilepath(fs.UriToFile(location.uri))
  const lnum = location.range.start.line + 1
  const col = location.range.start.character + 1

  execute printf("edit +call\\ setcursorcharpos(%d,\\ %d) %s", lnum, col, filepath)
enddef

# Handle LocationLink type result
def GoToLocationLink(location: dict<any>): void
  const filepath = RelativeFilepath(fs.UriToFile(location.targetUri))
  const lnum = location.targetRange.start.line + 1
  const col = location.targetRange.start.character + 1

  execute printf("edit +call\\ setcursorcharpos(%d,\\ %d) %s", lnum, col, filepath)
enddef

def OnResponse(ch: channel, response: any): void
  logger.LogDebug('Response `textDocument/definition`: ' .. response->string())
  const result = response->get('result', {})

  if result->empty()
    # Do nothing
    return
  endif

  if result->type() == v:t_dict
    const filepath = RelativeFilepath(fs.UriToFile(result.uri))
    const lnum = result.range.start.line + 1
    const col = result.range.start.character + 1

    execute printf("edit +call\\ setcursorcharpos(%d,\\ %d) %s", lnum, col, filepath)

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

def MakeRequest(ch: channel, params: dict<any>): void
  protocol.RequestAsync(ch, 'textDocument/definition', params, OnResponse)
  logger.LogDebug('Request `textDocument/definition`: ' .. params->string())
enddef

export def Request(ch: channel, buf: number): void
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
    workDoneToken: random.RandomStr(),
    # partialResultToken: '',
  }

  MakeRequest(ch, params)
enddef

export def Register(ch: channel, registrationOptions: any, lspClientConfig: dict<any>): void
  logger.LogDebug('Received Dynamic Registration `textDocument/definition`: ' .. registrationOptions->string())
enddef
