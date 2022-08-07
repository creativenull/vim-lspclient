vim9script

import '../../logger.vim'
import '../../fs.vim'
import '../../core/types.vim'
import '../../vim/sign.vim'

const DiagnosticSeverity = types.DiagnosticSeverity
const SignSeverity = sign.SeverityType

def CreateLocListTextFormat(diagnostic: dict<any>): string
  const noSource = diagnostic->get('source', '')->empty()

  if noSource
    return diagnostic.message
  endif

  return printf('%s: %s', diagnostic.source, diagnostic.message)
enddef

def CreateLocList(diagnostics: list<any>, filename: string): list<any>
  return diagnostics->mapnew((i, diagnostic) => ({
    filename: filename,
    lnum: diagnostic.range.start.line + 1,
    col: diagnostic.range.start.character + 1,
    end_lnum: diagnostic.range.end.line + 1,
    end_col: diagnostic.range.end.character + 1,
    nr: diagnostic->get('code', 0)->type() == v:t_number ? diagnostic.code : 0,
    type: DiagnosticSeverity[diagnostic.severity],
    text: CreateLocListTextFormat(diagnostic),
  }))
enddef

def CreateSigns(diagnostics: list<any>, buf: number): list<any>
  return diagnostics->mapnew((i, diagnostic) => ({
    buf: buf,
    lnum: diagnostic.range.start.line + 1,
    level: SignSeverity[DiagnosticSeverity[diagnostic.severity]],
  }))
enddef

export def HandleRequest(request: any, lspClientConfig: dict<any>): void
  const params = request.params
  const filename = fs.UriToFile(params.uri)
  const buf = bufnr(filename)
  const diagnostics = params->get('diagnostics', [])

  # Set location-list
  if diagnostics->empty()
    setloclist(0, [], 'r')
    sign.UnplaceBuffer(buf)

    return
  endif

  const loclist = CreateLocList(diagnostics, filename)
  setloclist(0, loclist, 'r')

  # Generate signs from diagnostics with a clean slate
  sign.UnplaceBuffer(buf)
  const signs = CreateSigns(diagnostics, buf)
  sign.PlaceList(signs)
enddef
