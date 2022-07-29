if !has('vim9script')
  echoerr '[LSPCLIENT] vim >= 9 is required'
  finish
endif

vim9script

if exists('g:loaded_lspclient')
  finish
endif

import autoload 'lspclient/vim/checkhealth.vim'
import autoload 'lspclient/logger.vim'

command! LSPClientCheckHealth call checkhealth.Info()

command! LSPClientLog call logger.OpenLogFilepath()
command! LSPClientLogClear call logger.ClearLogContents()
command! LSPClientDiagnostics echom 'WIP!'

g:loaded_lspclient = true
