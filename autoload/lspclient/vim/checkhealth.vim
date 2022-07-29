vim9script

import '../logger.vim'

export def Info(): void
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
    logger.PrintError('Following are not available for the plugin to work properly: ' .. errlist->join(','))
  else
    logger.PrintInfo('All Checks Passed!')
  endif
enddef
