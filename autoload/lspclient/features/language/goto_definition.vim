vim9script

import '../../core/protocol.vim'
import '../../fs.vim'
import '../../logger.vim'
import '../../random.vim'

def RelativeFilepath(filepath: string): string
  return substitute(filepath, fs.GetProjectRoot('/'), '', '')
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

    execute printf("edit +%d %s", lnum, filepath)

    return
  endif

  if result->type() == v:t_list
    if result->len() == 1
      const location = result[0]
      const filepath = RelativeFilepath(fs.UriToFile(location.uri))
      const lnum = location.range.start.line + 1

      execute printf("edit +%d %s", lnum, filepath)
    else
      # WIP
      # Show a list of possible files with the same definition
      # Preferebly in a quickfix list
      var qlist = []

      for item in result
        qlist->add({
          filename: RelativeFilepath(fs.UriToFile(item.uri)),
          lnum: item.range.start.line + 1,
          col: item.range.start.character + 1,
          valid: false,
        })
      endfor

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
