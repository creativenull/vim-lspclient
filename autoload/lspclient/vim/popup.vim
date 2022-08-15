vim9script

import './colors.vim'

const borderchars = ['─', '│', '─', '│', '╭', '╮', '╯', '╰']
const title = 'LSP Client'

var isNotifyOpen = false
var isPopupAtCursorOpen = false
var isPopupLoading = false

export const SeverityType = {
  E: 'Error',
  W: 'Warning',
  I: 'Info',
  H: 'Hint',
}

def OnCloseNotify(_popupId: any, _result: any): void
  isNotifyOpen = false
enddef

def OnClosePopupAtCursor(_popupId: any, _result: any): void
  isPopupAtCursorOpen = false
enddef

def OnClosePopupLoading(_popupId: any, _result: any): void
  isPopupLoading = false
enddef

export def DefineHighlights(): void
  hlset([
    { name: 'LSPClientPopupBorder', guifg: colors.Text, guibg: 'NONE' },
    { name: 'LSPClientPopupBorderError', guifg: colors.Error, guibg: 'NONE' },
    { name: 'LSPClientPopupBorderWarning', guifg: colors.Warning, guibg: 'NONE' },
    { name: 'LSPClientPopupBorderHint', guifg: colors.Hint, guibg: 'NONE' },
    { name: 'LSPClientPopupBorderInfo', guifg: colors.Info, guibg: 'NONE' },
    { name: 'LSPClientPopup', guifg: colors.Text, guibg: 'NONE' },
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
    title: title,
    line: 2,
    col: winwidth(0) - 50,
    minwidth: 50,
    maxwidth: 50,
    highlight: 'LSPClientPopup',
    borderchars: borderchars,
    borderhighlight: [printf('LSPClientPopupBorder%s', level)],
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
    highlight: 'LSPClientPopup',
    border: [],
    padding: [0, 1, 0, 1],
    borderchars: borderchars,
    borderhighlight: [printf('LSPClientPopupBorder%s', level)],
    callback: OnClosePopupAtCursor,
  })
enddef

export def Loading(): void
  var dots = [
		"[ ●    ]",
		"[  ●   ]",
		"[   ●  ]",
		"[    ● ]",
		"[     ●]",
		"[    ● ]",
		"[   ●  ]",
		"[  ●   ]",
		"[ ●    ]",
		"[●     ]"
  ]
  var currentDotPos = 0

  const loadingWinId = popup_atcursor(dots[0], {
    pos: 'topleft',
    highlight: 'LSPClientPopup',
    border: [],
    padding: [0, 1, 0, 1],
    borderchars: borderchars,
    borderhighlight: ['LSPClientPopupBorder'],
  })

  def RenderLoader(timerId: number): void
    currentDotPos += 1

    if currentDotPos == dots->len()
      currentDotPos = 0
    endif

    popup_settext(loadingWinId, dots[currentDotPos])
  enddef

  const loadingTimerId = timer_start(100, RenderLoader, { repeat: -1 })
enddef
