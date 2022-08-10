vim9script

import '../../logger.vim'
import '../../fs.vim'
import '../../core/types.vim'
import '../../vim/sign.vim'

# Track by each buffer
var bufferLocationList = {}

const DiagnosticSeverity = types.DiagnosticSeverity
const SignSeverity = sign.SeverityType

def CreateLocListTextFormat(message: string, source: string, severity: string, code: any): string
  return printf('%s [%s %s%s]', message, source, severity, code)
enddef

def CreateLocList(diagnostics: list<any>, buf: number, lspClientConfig: dict<any>): list<any>
  def MapLocList(_i: number, diagnostic: dict<any>): dict<any>
    const code = diagnostic->get('code') != 0 ? diagnostic.code : 0
    const source = diagnostic->get('source', lspClientConfig.name)
    const message = diagnostic.message
    const severity = DiagnosticSeverity[diagnostic.severity]

    return {
      bufnr: buf,
      text: CreateLocListTextFormat(message, source, severity, code),
      nr: code,
      type: severity,
      lnum: diagnostic.range.start.line + 1,
      col: diagnostic.range.start.character + 1,
      end_lnum: diagnostic.range.end.line + 1,
      end_col: diagnostic.range.end.character + 1,
    }
  enddef

  return diagnostics->mapnew(MapLocList)
enddef

def CreateSigns(diagnostics: list<any>, buf: number): list<any>
  return diagnostics->mapnew((i, diagnostic) => ({
    buf: buf,
    lnum: diagnostic.range.start.line + 1,
    level: SignSeverity[DiagnosticSeverity[diagnostic.severity]],
  }))
enddef

# Handle diagnostics to a location list and signs.
# Show on a per buffer basis
export def HandleRequest(request: any, lspClientConfig: dict<any>): void
  const params = request.params
  const filename = fs.UriToFile(params.uri)
  const buf = bufnr(filename)
  const diagnostics = params->get('diagnostics', [])

  # Reset
  var loclist = []

  if diagnostics->empty()
    bufferLocationList[buf] = []
  else
    bufferLocationList[buf] = CreateLocList(diagnostics, buf, lspClientConfig)
  endif

  # Merge for every buffer and then set
  for b in bufferLocationList->keys()
    loclist->extend(bufferLocationList[b])
  endfor

  setloclist(0, loclist, 'r')

  # Generate signs from diagnostics with a clean slate
  sign.UnplaceBuffer(buf)
  const signs = CreateSigns(diagnostics, buf)
  sign.PlaceList(signs)
enddef
