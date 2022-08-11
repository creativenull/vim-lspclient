vim9script

import './colors.vim'

export def DefineHighlights(): void
  hlset([
    {
      name: 'LSPClientDiagnosticError',
      cterm: { underline: true },
      guifg: colors.Error,
      guibg: 'NONE',
      gui: { undercurl: true },
    },
    {
      name: 'LSPClientDiagnosticWarning',
      cterm: { underline: true },
      guifg: colors.Warning,
      guibg: 'NONE',
      gui: { undercurl: true },
    },
    {
      name: 'LSPClientDiagnosticHint',
      cterm: { underline: true },
      guifg: colors.Hint,
      guibg: 'NONE',
      gui: { undercurl: true },
    },
    {
      name: 'LSPClientDiagnosticInfo',
      cterm: { underline: true },
      guifg: colors.Info,
      guibg: 'NONE',
      gui: { undercurl: true },
    },
  ])
enddef

export def DefineTextProps(): void
  prop_type_add('LSPClientDiagnosticPropTextError', { highlight: 'LSPClientDiagnosticError' })
  prop_type_add('LSPClientDiagnosticPropTextWarning', { highlight: 'LSPClientDiagnosticWarning' })
  prop_type_add('LSPClientDiagnosticPropTextHint', { highlight: 'LSPClientDiagnosticHint' })
  prop_type_add('LSPClientDiagnosticPropTextInfo', { highlight: 'LSPClientDiagnosticInfo' })
enddef
