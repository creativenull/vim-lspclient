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
import autoload 'lspclient/vim/popup.vim'
import autoload 'lspclient/logger.vim'
import autoload 'lspclient.vim'

command! LSPClientCheckHealth call checkhealth.Info()

command! LSPClientLog call logger.OpenLogFilepath()
command! LSPClientLogClear call logger.ClearLogContents()
command! LSPClientInfo call lspclient.Info()

command! LSPClientGotoDefinition call lspclient.GotoDefinition()
command! LSPClientGotoDeclaration call lspclient.GotoDeclaration()

command! LSPClientDiagnostics lopen
command! LSPClientHoverDiagnostic call lspclient.PopupDiagnosticAtCursor()

# Popup Highlights
popup.DefineHighlights()

# Sign Highlights and Definitions
sign.DefineHighlights()
sign.DefineSigns()

g:loaded_lspclient = true
