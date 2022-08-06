if !has('vim9script')
  echoerr '[LSPCLIENT] vim >= 9 is required'
  finish
endif

vim9script

if exists('g:loaded_lspclient')
  finish
endif

import autoload 'lspclient/vim/checkhealth.vim'
import autoload 'lspclient/vim/sign.vim'
import autoload 'lspclient/logger.vim'
import autoload 'lspclient.vim'

command! LSPClientCheckHealth call checkhealth.Info()

command! LSPClientLog call logger.OpenLogFilepath()
command! LSPClientLogClear call logger.ClearLogContents()
command! LSPClientInfo call lspclient.Info()

command! LSPClientGotoDefinition call lspclient.GotoDefinition()
command! LSPClientGotoDeclaration call lspclient.GotoDeclaration()

command! LSPClientDiagnostics echom 'WIP!'

# Popup Highlights
highlight LSPClientPopupBorder guifg=#eeeeee guibg=NONE
highlight LSPClientPopupInfo guifg=#eeeeee guibg=NONE
highlight default link LSPClientPopupError ErrorMsg
highlight default link LSPClientPopupWarning WarningMsg

# Sign Highlights and Definitions
sign.DefineHighlights()
sign.DefineSigns()

g:loaded_lspclient = true
