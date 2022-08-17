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

# Change from 0-based index to 1-based for lines and cols
# Returns a List with values: [lnum, col, end_lnum, end_col]
def RangeOffset(range: dict<any>): list<number>
  var offsets = []

  offsets->add(range.start.line + 1)
  offsets->add(range.start.character + 1)

  offsets->add(range.end.line + 1)
  offsets->add(range.end.character + 1)

  return offsets
enddef

def LocationListText(message: string, source: string, severity: string, code: any): string
  return printf('%s [%s %s%s]', message, source, severity, code)
enddef

def MakeBufLocationList(buf: number, diagnostics: list<any>, lspClientConfig: dict<any>): list<any>
  def MapLocList(_i: number, diagnostic: dict<any>): dict<any>
    const code = diagnostic->get('code') != 0 ? diagnostic.code : 0
    const source = diagnostic->get('source', lspClientConfig.name)
    const message = diagnostic.message
    const severity = DiagnosticSeverity[diagnostic.severity]
    const [lnum, col, end_lnum, end_col] = RangeOffset(diagnostic.range)

    return {
      bufnr: buf,
      text: LocationListText(message, source, severity, code),
      nr: code,
      type: severity == 'H' ? 'I' : severity,
      lnum: lnum,
      col: col,
      end_lnum: end_lnum,
      end_col: end_col,
      valid: true,
    }
  enddef

  return diagnostics->mapnew(MapLocList)
enddef

def LocationListTextFunc(info: dict<any>): list<string>
  var textFormats = []
  const list = getloclist(info.winid)
  for item in list
    const filename = bufname(item.bufnr)
    const message = item.text->substitute("\n", '', 'g')
    const text = printf(
      '%s | %s:%s %s | %s',
      filename,
      item.lnum,
      item.col,
      LocationListSeverity[item.type]->tolower(),
      message
    )

    textFormats->add(text)
  endfor

  return textFormats
enddef

def RenderBufLocationList(buf: number, diagnostics: list<any>, lspClientConfig: dict<any>): void
  const winId = bufwinid(buf)

  # Reset
  var loclist = []

  if diagnostics->empty()
    bufferLocationList[buf] = []
  else
    bufferLocationList[buf] = MakeBufLocationList(buf, diagnostics, lspClientConfig)
  endif

  # Merge for every buffer and then set
  for b in bufferLocationList->keys()
    loclist = loclist->extendnew(bufferLocationList[b])
  endfor

  setloclist(winId, [], 'r')
  setloclist(winId, [], 'a', {
    title: 'Diagnostics',
    items: loclist,
    quickfixtextfunc: LocationListTextFunc,
  })
enddef

def ClearBufSigns(buf: number): void
  sign.UnplaceBuffer(buf)
enddef

def RenderBufSigns(buf: number, diagnostics: list<any>): void
  ClearBufSigns(buf)

  const signs = diagnostics->mapnew((_i, diagnostic) => ({
    buf: buf,
    lnum: diagnostic.range.start.line + 1,
    level: SignSeverity[DiagnosticSeverity[diagnostic.severity]],
  }))

  sign.PlaceList(signs)
enddef

def ClearBufTextProps(buf: number): void
  prop_remove({ type: 'LSPClientDiagnosticPropTextError', bufnr: buf })
  prop_remove({ type: 'LSPClientDiagnosticPropTextWarning', bufnr: buf })
  prop_remove({ type: 'LSPClientDiagnosticPropTextHint', bufnr: buf })
  prop_remove({ type: 'LSPClientDiagnosticPropTextInfo', bufnr: buf })
enddef

def RenderBufTextProps(buf: number, diagnostics: list<any>): void
  ClearBufTextProps(buf)

  for diagnostic in diagnostics
    const [lnum, col, _, end_col] = RangeOffset(diagnostic.range)
    const severity = LocationListSeverity[DiagnosticSeverity[diagnostic.severity]]

    # Get byte index and not a number for column
    const bytecol = virtcol2col(0, lnum, col)

    if bytecol > 0
      prop_add(lnum, bytecol, {
        bufnr: buf,
        end_col: end_col,
        type: printf('LSPClientDiagnosticPropText%s', severity),
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

  # Re-render Location List
  RenderBufLocationList(buf, diagnostics, lspClientConfig)

  # Re-render signs
  RenderBufSigns(buf, diagnostics)

  # Re-render text props
  RenderBufTextProps(buf, diagnostics)
enddef
