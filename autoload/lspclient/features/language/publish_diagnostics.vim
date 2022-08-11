vim9script

import '../../logger.vim'
import '../../fs.vim'
import '../../core/types.vim'
import '../../vim/sign.vim'

# Track by each buffer
var bufferLocationList = {}

const LocationListSeverity = {
  'E': 'Error',
  'W': 'Warning',
  'I': 'Info',
  'H': 'Hint',
}

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

def LocListTextFunc(info: dict<any>): list<string>
  var textFormats = []
  const list = getloclist(info.winid)
  for item in list
    const filename = bufname(item.bufnr)
    textFormats->add(printf('%s:%s:%s %s - %s', filename, item.lnum, item.col, LocationListSeverity[item.type], item.text))
  endfor

  return textFormats
enddef

def CreateSigns(diagnostics: list<any>, buf: number): list<any>
  return diagnostics->mapnew((i, diagnostic) => ({
    buf: buf,
    lnum: diagnostic.range.start.line + 1,
    level: SignSeverity[DiagnosticSeverity[diagnostic.severity]],
  }))
enddef

def ClearBufTextProps(buf: number): void
  prop_remove({ type: 'LSPClientDiagnosticPropTextError', bufnr: buf })
  prop_remove({ type: 'LSPClientDiagnosticPropTextWarning', bufnr: buf })
  prop_remove({ type: 'LSPClientDiagnosticPropTextHint', bufnr: buf })
  prop_remove({ type: 'LSPClientDiagnosticPropTextInfo', bufnr: buf })
enddef

def RenderBufTextProps(buf: number, loclist: list<any>): void
  for item in loclist
    # Get byte index and not a number for column
    const col = virtcol2col(0, item.lnum, item.col)

    if col > 0
      prop_add(item.lnum, col, {
        bufnr: buf,
        end_col: item.end_col,
        type: printf('LSPClientDiagnosticPropText%s', LocationListSeverity[item.type]),
      })
    endif
  endfor
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
    loclist = loclist->extendnew(bufferLocationList[b])
  endfor

  setloclist(0, [], 'r')
  setloclist(0, [], 'a', {
    title: 'LSPClient Diagnostics',
    items: loclist,
    quickfixtextfunc: LocListTextFunc,
  })

  # Re-render signs for generated diagnostics
  sign.UnplaceBuffer(buf)
  const signs = CreateSigns(diagnostics, buf)
  sign.PlaceList(signs)

  # Re-render prop text for generated diagnostics
  ClearBufTextProps(buf)
  RenderBufTextProps(buf, loclist)
enddef
