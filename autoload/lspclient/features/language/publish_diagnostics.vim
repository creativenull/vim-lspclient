vim9script

import '../../logger.vim'
import '../../fs.vim'
import '../../core/types.vim'
import '../../vim/sign.vim'

# Track by each buffer
var bufferLocationList = {}

var publishedDiagnostics = {
  qf: {},
  signs: {},
  textprops: {},
}

const LocationListSeverity = {
  'E': 'Error',
  'W': 'Warning',
  'I': 'Info',
  'H': 'Hint',
}

const QfListSeverity = {
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

# Generate quickfix list from LSP diagnostics
def MakeBufQfList(buf: number, diagnostics: list<any>, lspClientConfig: dict<any>): list<any>
  def MakeQfText(diagnostic: dict<any>): string
    const source = diagnostic->get('source', lspClientConfig.name)

    if diagnostic->has_key('code')
      return printf('%s [%s %s]', diagnostic.message, source, diagnostic.code)
    endif

    return printf('%s [%s]', diagnostic.message, source)
  enddef

  def MapQfFunc(_i: number, diagnostic: dict<any>): dict<any>
    const [lnum, col, end_lnum, end_col] = RangeOffset(diagnostic.range)

    # Required
    var qfItem = {
      bufnr: buf,
      text: MakeQfText(diagnostic),
      lnum: lnum,
      end_lnum: end_lnum,
      col: col,
      end_col: end_col,
      valid: 1,
    }

    # Optional
    if diagnostic->has_key('code')
      qfItem.nr = diagnostic.code
    endif

    if diagnostic->has_key('severity')
      # Only takes E, W and I
      const severity = DiagnosticSeverity[diagnostic.severity]
      qfItem.type = severity == 'H' ? 'I' : severity
    endif

    return qfItem
  enddef

  return diagnostics->mapnew(MapQfFunc)
enddef

# Generate signs from LSP diagnostics
def MakeBufSignList(buf: number, diagnostics: list<any>): list<any>
  def MapSignFunc(_i: number, diagnostic: dict<any>): dict<any>
    const [lnum, _, _, _] = RangeOffset(diagnostic.range)
    var severity = 'I'

    if diagnostic->has_key('severity')
      severity = DiagnosticSeverity[diagnostic.severity]
    endif

    return {
      buffer: buf,
      lnum: lnum,
      group: sign.Group,
      name: printf('LSPClientSign%s', QfListSeverity[severity]),
      priority: 100,
    }
  enddef

  return diagnostics->mapnew(MapSignFunc)
enddef

# Generate textprops to hightlight text from LSP diagnostics
def MakeBufTextProps(buf: number, diagnostics: list<any>): dict<any>
  var errorTextProps = []
  var warningTextProps = []
  var hintTextProps = []
  var infoTextProps = []

  for diagnostic in diagnostics
    const [lnum, col, end_lnum, end_col] = RangeOffset(diagnostic.range)

    if !diagnostic->has_key('severity')
      # By default, diagnostic will be error
      errorTextProps->add([lnum, col, end_lnum, end_col])
      continue
    endif

    if DiagnosticSeverity[diagnostic.severity] == 'E'
      errorTextProps->add([lnum, col, end_lnum, end_col])
    elseif DiagnosticSeverity[diagnostic.severity] == 'W'
      warningTextProps->add([lnum, col, end_lnum, end_col])
    elseif DiagnosticSeverity[diagnostic.severity] == 'H'
      hintTextProps->add([lnum, col, end_lnum, end_col])
    elseif DiagnosticSeverity[diagnostic.severity] == 'I'
      infoTextProps->add([lnum, col, end_lnum, end_col])
    endif
  endfor

  return {
    LSPClientDiagnosticPropTextError: errorTextProps,
    LSPClientDiagnosticPropTextWarning: warningTextProps,
    LSPClientDiagnosticPropTextHint: hintTextProps,
    LSPClientDiagnosticPropTextInfo: infoTextProps,
  }
enddef

# Handle diagnostics to show to user
export def HandleRequest(request: any, lspClientConfig: dict<any>): void
  const buf = bufnr(fs.UriToFile(request.params.uri))
  const diagnostics = request.params->get('diagnostics', [])

  if diagnostics->empty()
    publishedDiagnostics.qf[buf] = []
    publishedDiagnostics.signs[buf] = []
    publishedDiagnostics.textprops[buf] = []
  endif

  # Quickfix
  publishedDiagnostics.qf[buf] = MakeBufQfList(buf, diagnostics, lspClientConfig)

  var qflist = []
  for b in publishedDiagnostics.qf->keys()
    qflist = qflist->extendnew(publishedDiagnostics.qf[b])
  endfor

  # setqflist(qflist, 'r')
  setqflist([], 'r')
  setqflist([], 'a', {
    title: 'Diagnostics',
    items: qflist,
  })

  # Signs
  # Clear placed signs first
  sign_unplace(sign.Group, { buffer: buf })

  publishedDiagnostics.signs[buf] = MakeBufSignList(buf, diagnostics)

  var signList = []
  for b in publishedDiagnostics.signs->keys()
    signList = signList->extendnew(publishedDiagnostics.signs[b])
  endfor

  sign_placelist(signList)

  # Textprops
  # clear first then assign the highlight
  prop_remove({ type: 'LSPClientDiagnosticPropTextError', bufnr: buf })
  prop_remove({ type: 'LSPClientDiagnosticPropTextWarning', bufnr: buf })
  prop_remove({ type: 'LSPClientDiagnosticPropTextHint', bufnr: buf })
  prop_remove({ type: 'LSPClientDiagnosticPropTextInfo', bufnr: buf })

  publishedDiagnostics.textprops[buf] = MakeBufTextProps(buf, diagnostics)

  for b in publishedDiagnostics.textprops->keys()
    for propType in publishedDiagnostics.textprops[b]->keys()
      try
        prop_add_list({ bufnr: b->str2nr(10), type: propType }, publishedDiagnostics.textprops[b][propType])
      catch
        continue
      endtry
    endfor
  endfor
enddef
