if !has('vim9script')
  echoerr '[LSPCLIENT] vim >= 9 is required'
  finish
endif

vim9script

if exists('g:loaded_lspclient')
  finish
endif

import autoload 'lspclient.vim'
import autoload 'lspclient/logger.vim'
import autoload 'lspclient/vim/checkhealth.vim'
import autoload 'lspclient/vim/popup.vim'
import autoload 'lspclient/vim/sign.vim'
import autoload 'lspclient/vim/textprop.vim'

command! LSPClientCheckHealth call checkhealth.Info()

command! LSPClientLog call logger.OpenLogFilepath()
command! LSPClientLogClear call logger.ClearLogContents()
command! LSPClientInfo call lspclient.Info()

command! LSPClientGotoDefinition call lspclient.GotoDefinition()
nmap <unique> <silent> <Plug>(lspclient_definition) <ScriptCmd>lspclient.GotoDefinition()<CR>

command! LSPClientGotoDeclaration call lspclient.GotoDeclaration()
nmap <unique> <silent> <Plug>(lspclient_declaration) <ScriptCmd>lspclient.GotoDeclaration()<CR>

command! LSPClientDiagnostics lopen
nmap <unique> <silent> <Plug>(lspclient_diagnostics) <Cmd>lopen<CR>

command! LSPClientDiagnosticHover call lspclient.PopupDiagnosticAtCursor()
nmap <unique> <silent> <Plug>(lspclient_diagnostic_hover) <ScriptCmd>lspclient.PopupDiagnosticAtCursor()<CR>

# Popup Highlights
popup.DefineHighlights()

# Sign Highlights and Definitions
sign.DefineHighlights()
sign.DefineSigns()

# Text props
textprop.DefineHighlights()
textprop.DefineTextProps()

g:loaded_lspclient = true
