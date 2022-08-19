vim9script

import '../logger.vim'
import './colors.vim'

export const Group = 'LSPClient'

export const SeverityType = {
  E: 'Error',
  W: 'Warning',
  I: 'Info',
  H: 'Hint',
}

# Using tailwindcss colors
export def DefineHighlights(): void
  hlset([
    { name: 'LSPClientSignError', guifg: colors.Error, guibg: 'NONE' },
    { name: 'LSPClientSignErrorLine', guifg: colors.Error, guibg: 'NONE', gui: { underline: true } },
    { name: 'LSPClientSignWarning', guifg: colors.Warning, guibg: 'NONE' },
    { name: 'LSPClientSignWarningLine', guifg: colors.Warning, guibg: 'NONE', gui: { underline: true } },
    { name: 'LSPClientSignInfo', guifg: colors.Info, guibg: 'NONE' },
    { name: 'LSPClientSignInfoLine', guifg: colors.Info, guibg: 'NONE' },
    { name: 'LSPClientSignHint', guifg: colors.Hint, guibg: 'NONE' },
    { name: 'LSPClientSignHintLine', guifg: colors.Hint, guibg: 'NONE' },
  ])
enddef

export def DefineSigns(): void
  const lspClientSigns = [
    {
      name: 'LSPClientSignError',
      text: 'E',
      texthl: 'LSPClientSignError',
      numhl: 'LSPClientSignError',
    },
    {
      name: 'LSPClientSignWarning',
      text: 'W',
      texthl: 'LSPClientSignWarning',
      numhl: 'LSPClientSignWarning',
    },
    {
      name: 'LSPClientSignInfo',
      text: 'I',
      texthl: 'LSPClientSignInfo',
      numhl: 'LSPClientSignInfo',
    },
    {
      name: 'LSPClientSignHint',
      text: 'H',
      texthl: 'LSPClientSignHint',
      numhl: 'LSPClientSignHint',
    },
  ]

  const success = lspClientSigns->sign_define()

  if !success
    logger.PrintError('Failed to define signs')
  endif
enddef
