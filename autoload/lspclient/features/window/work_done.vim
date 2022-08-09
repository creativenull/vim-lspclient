vim9script

import '../../core/protocol.vim'
import '../../logger.vim'

var tokens = []

export def Create(ch: channel, request: any): void
  tokens->add(request.params.token)
  protocol.ResponseAsync(ch, request.id, {})
  logger.LogDebug('Response `window/workDoneProgress/create`: {}')
enddef

export def Cancel(ch: channel, token: any): void
  const idx = tokens->index(token)

  if idx != -1
    tokens->remove(idx)
    const params = { token: token }
    protocol.NotifyAsync(ch, 'window/workDoneProgress/cancel', params)
    logger.LogDebug('Notify `window/workDoneProgress/cancel`: ' .. params->string())
  endif
enddef
