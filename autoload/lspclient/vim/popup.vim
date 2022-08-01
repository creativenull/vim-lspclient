vim9script

const borderchars = ['─', '│', '─', '│', '╭', '╮', '╯', '╰']
const title = 'LSP Client'

export def Notify(level: string, message: string)
  popup_notification(message, {
    line: 2,
    col: winwidth(0) - 50,
    minwidth: 50,
    maxwidth: 50,
    highlight: printf('LspClientPopup%s', level),
    borderchars: borderchars,
    borderhighlight: ['LspClientPopupBorder'],
    title: title,
  })
enddef
