vim9script

import '../logger.vim'
import './colors.vim'

var placed = []

export const namespace = 'LSPClient'
export const SeverityType = {
  E: 'Error',
  W: 'Warning',
  I: 'Info',
  H: 'Hint',
}

# Using tailwindcss colors
export def DefineHighlights(): void
  hlset([
    { name: 'LSPClientSignError', guifg: colors.Error, gubg: 'NONE' },
    { name: 'LSPClientSignErrorLine', guifg: colors.Error, guibg: 'NONE', gui: { underline: true } },
    { name: 'LSPClientSignWarning', guifg: colors.Warning, gubg: 'NONE' },
    { name: 'LSPClientSignWarningLine', guifg: colors.Warning, guibg: 'NONE', gui: { underline: true } },
    { name: 'LSPClientSignInfo', guifg: colors.Info, gubg: 'NONE' },
    { name: 'LSPClientSignInfoLine', guifg: colors.Info, guibg: 'NONE' },
    { name: 'LSPClientSignHint', guifg: colors.Hint, gubg: 'NONE' },
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

export def Place(level: string, buf: number, lnum: number): number
  const sign = printf('LSPClientSign%s', level)
  const id = sign_place(0, namespace, sign, buf, {
    lnum: lnum,
    priority: 100,
  })

  # Track placed signs
  placed->add(id)

  return id
enddef

export def PlaceList(signs: list<dict<any>>): void
  for sign in signs
    Place(sign.level, sign.buf, sign.lnum)
  endfor
enddef

export def Unplace(id: number): void
  sign_unplace(namespace, { id: id })
enddef

export def UnplaceBuffer(buf: number): void
  if !buf->bufexists()
    return
  endif

  sign_unplace(namespace, { buffer: buf })
enddef

export def UnplaceAll(): void
  sign_unplace(namespace)
enddef
