vim9script

const borderchars = ['─', '│', '─', '│', '╭', '╮', '╯', '╰']
const title = 'LSP Client'

var isNotifyOpen = false

def OnCloseNotify(popupId: any, result: any): void
  isNotifyOpen = false
enddef

export def Notify(level: string, message: string): void
  if isNotifyOpen
    return
  endif

  isNotifyOpen = true
  popup_notification(message, {
    line: 2,
    col: winwidth(0) - 50,
    minwidth: 50,
    maxwidth: 50,
    highlight: printf('LSPClientPopup%s', level),
    borderchars: borderchars,
    borderhighlight: ['LSPClientPopupBorder'],
    title: title,
    time: 5000,
    callback: OnCloseNotify,
  })
enddef
