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
import autoload 'lspclient/features/language/document_highlight.vim'

command! LSPClientCheckHealth call checkhealth.Info()

command! LSPClientLog call logger.OpenLogFilepath()
command! LSPClientLogClear call logger.ClearLogContents()
command! LSPClientInfo call lspclient.Info()

command! LSPClientGotoDefinition call lspclient.GotoDefinition()
nmap <unique> <silent> <Plug>(lspclient_definition) <ScriptCmd>lspclient.GotoDefinition()<CR>

command! LSPClientGotoDeclaration call lspclient.GotoDeclaration()
nmap <unique> <silent> <Plug>(lspclient_declaration) <ScriptCmd>lspclient.GotoDeclaration()<CR>

command! LSPClientGotoTypeDefinition call lspclient.GotoTypeDefinition()
nmap <unique> <silent> <Plug>(lspclient_type_definition) <ScriptCmd>lspclient.GotoTypeDefinition()<CR>

command! LSPClientGotoImplementation call lspclient.GotoImplementation()
nmap <unique> <silent> <Plug>(lspclient_implementation) <ScriptCmd>lspclient.GotoImplementation()<CR>

command! LSPClientFindReferences call lspclient.FindReferences()
nmap <unique> <silent> <Plug>(lspclient_references) <ScriptCmd>lspclient.FindReferences()<CR>

command! LSPClientReferenceNext call lspclient.ReferenceNext()
nmap <unique> <silent> <Plug>(lspclient_reference_next) <ScriptCmd>lspclient.ReferenceNext()<CR>

command! LSPClienReferencePrev call lspclient.ReferencePrev()
nmap <unique> <silent> <Plug>(lspclient_reference_prev) <ScriptCmd>lspclient.ReferencePrev()<CR>

command! LSPClientDocumentHighlight call lspclient.DocumentHighlight()
command! LSPClientDocumentHighlightClear call lspclient.DocumentHighlightClear()
nmap <unique> <silent> <Plug>(lspclient_document_highlight) <ScriptCmd>lspclient.DocumentHighlight()<CR>

command! LSPClientCodeLens call lspclient.CodeLens()
nmap <unique> <silent> <Plug>(lspclient_code_lens) <ScriptCmd>lspclient.CodeLens()<CR>

command! LSPClientDocumentSymbols call lspclient.DocumentSymbols()
nmap <unique> <silent> <Plug>(lspclient_document_symbols) <ScriptCmd>lspclient.DocumentSymbols()<CR>

command! LSPClientDiagnostics call lspclient.Diagnostics()
nmap <unique> <silent> <Plug>(lspclient_diagnostics) <ScriptCmd>lspclient.Diagnostics()<CR>

command! LSPClientDiagnosticNext call lspclient.DiagnosticNext()
nmap <unique> <silent> <Plug>(lspclient_diagnostic_next) <ScriptCmd>lspclient.DiagnosticNext()<CR>

command! LSPClientDiagnosticPrev call lspclient.DiagnosticNext()
nmap <unique> <silent> <Plug>(lspclient_diagnostic_prev) <ScriptCmd>lspclient.DiagnosticPrev()<CR>

command! LSPClientDiagnosticHover call lspclient.DiagnosticPopupAtCursor()
nmap <unique> <silent> <Plug>(lspclient_diagnostic_hover) <ScriptCmd>lspclient.DiagnosticPopupAtCursor()<CR>

command! LSPClientHover call lspclient.Hover()
nmap <unique> <silent> <Plug>(lspclient_hover) <ScriptCmd>lspclient.Hover()<CR>

# Popup Highlights
popup.DefineHighlights()

# Sign Highlights and Definitions
sign.DefineHighlights()
sign.DefineSigns()

# Text props
textprop.DefineHighlights()
textprop.DefineTextProps()

# Document highlight
document_highlight.DefineHighlights()

g:loaded_lspclient = true
