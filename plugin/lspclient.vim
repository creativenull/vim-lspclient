if !has('vim9script')
  echoerr '[LSPCLIENT] vim >= 9 is required'
  finish
endif

vim9script

if exists('g:loaded_lspclient')
  finish
endif

command! LSPClientLog call lspclient#core#log#OpenLogFilepath()
command! LSPClientLogClear call execute('!echo -n "" > ~/.cache/vim/lspclient.log')
command! LSPClientDiagnostics echom 'WIP!'

g:loaded_lspclient = true
