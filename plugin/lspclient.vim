if !has('vim9script')
  echoerr '[LSPCLIENT] vim >= 9 is required'
  finish
endif

vim9script

if exists('g:loaded_lspclient')
  finish
endif

def CheckHealth(): void
  const patch = 'patch-8.2.4758'
  var errlist = []

  if !has(patch)
    errlist->add(patch)
  elseif !has('channel')
    errlist->add('channel')
  elseif !has('job')
    errlist->add('job')
  elseif !has('timers')
    errlist->add('timers')
  endif

  if errlist->len() > 0
    echoerr '[LSPCLIENT] Following are not available for the plugin to work properly: ' .. errlist->join(',')
  else
    echomsg '[LSPCLIENT] All Checks Passed!'
  endif
enddef

command! LSPClientHealthCheck call <SID>CheckHealth()

command! LSPClientLog call lspclient#core#log#OpenLogFilepath()
command! LSPClientLogClear call execute('!echo -n "" > ~/.cache/vim/lspclient.log')
command! LSPClientDiagnostics echom 'WIP!'

g:loaded_lspclient = true
