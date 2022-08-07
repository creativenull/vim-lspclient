vim9script

import './colors.vim'

const borderchars = ['─', '│', '─', '│', '╭', '╮', '╯', '╰']
const title = 'LSP Client'

var isNotifyOpen = false
var isPopupAtCursorOpen = false

export const SeverityType = {
  E: 'Error',
  W: 'Warning',
  I: 'Info',
  H: 'Hint',
}

def OnCloseNotify(popupId: any, result: any): void
  isNotifyOpen = false
enddef

def OnClosePopupAtCursor(popupId: any, result: any): void
  isPopupAtCursorOpen = false
enddef

export def DefineHighlights(): void
  hlset([
    { name: 'LSPClientPopupBorder', guifg: '#eeeeee', guibg: 'NONE' },
    { name: 'LSPClientPopupBorderError', guifg: colors.Error, guibg: 'NONE' },
    { name: 'LSPClientPopupBorderWarning', guifg: colors.Warning, guibg: 'NONE' },
    { name: 'LSPClientPopupBorderHint', guifg: colors.Hint, guibg: 'NONE' },
    { name: 'LSPClientPopupBorderInfo', guifg: colors.Info, guibg: 'NONE' },
    { name: 'LSPClientPopupError', guifg: colors.Error, guibg: 'NONE' },
    { name: 'LSPClientPopupWarning', guifg: colors.Warning, guibg: 'NONE' },
    { name: 'LSPClientPopupHint', guifg: colors.Hint, guibg: 'NONE' },
    { name: 'LSPClientPopupInfo', guifg: colors.Info, guibg: 'NONE' },
  ])
enddef

export def Notify(message: any, level: string): void
  if isNotifyOpen
    return
  endif

  isNotifyOpen = true
  message->popup_notification({
    line: 2,
    col: winwidth(0) - 50,
    minwidth: 50,
    maxwidth: 50,
    highlight: printf('LSPClientPopup%s', level),
    borderchars: borderchars,
    borderhighlight: [printf('LSPClientPopupBorder%s', level)],
    title: title,
    time: 5000,
    callback: OnCloseNotify,
  })
enddef

export def Cursor(message: any, level: string): void
  if isPopupAtCursorOpen
    return
  endif

  isPopupAtCursorOpen = true
  message->popup_atcursor({
    title: level,
    pos: 'topleft',
    minwidth: 80,
    maxwidth: 80,
    highlight: printf('LSPClientPopup%s', level),
    border: [],
    padding: [0, 1, 0, 1],
    borderchars: borderchars,
    borderhighlight: [printf('LSPClientPopupBorder%s', level)],
    callback: OnClosePopupAtCursor,
  })
enddef
