vim9script

import '../../logger.vim'
import '../../fs.vim'
import '../../core/types.vim'
import '../../vim/popup.vim'

const DiagnosticSeverity = types.DiagnosticSeverity

def MakeLocListText(diagnostic: dict<any>): string
  return printf('%s: %s', diagnostic->get('source', ''), diagnostic.message)
enddef

export def HandlePublishDiagnosticsNotification(request: any, lspClientConfig: dict<any>): void
  const params = request.params
  const filename = fs.UriToFile(params.uri)
  const buf = bufnr(filename)
  const diagnostics = params->get('diagnostics', [])

  # Set location-list
  if diagnostics->empty()
    setloclist(0, [], 'r')
    # logger.PrintInfo('publishDiagnostics: []')

    return
  endif

  const loclist = diagnostics->mapnew((i, diagnostic) => ({
    filename: filename,
    lnum: diagnostic.range.start.line + 1,
    col: diagnostic.range.start.character + 1,
    end_lnum: diagnostic.range.end.line + 1,
    end_col: diagnostic.range.end.character + 1,
    nr: diagnostic->get('code', 0)->type() == v:t_number ? diagnostic.code : 0,
    type: DiagnosticSeverity[diagnostic.severity],
    text: MakeLocListText(diagnostic),
  }))

  setloclist(0, loclist, 'r')
  popup.Notify('Error', printf('Found %s problems', loclist->len()))
  # logger.PrintInfo('publishDiagnostics: ' .. loclist->string())
enddef
