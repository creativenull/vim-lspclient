vim9script

import '../../logger.vim'
import '../../fs.vim'
import '../../core/protocol.vim'

const method = 'workspace/executeCommand'

def OnResponse(ch: channel, response: dict<any>): void
  logger.LogDebug(printf('Got Response `%s`: %s', method, response->string()))

  const result = response->get('result', {})

  if result->empty()
    return
  endif

  # WIP: Implementation
enddef

export def Request(ch: channel, command: string, args: any, context: dict<any>): void
  const params = {
    command: command,
    arguments: args->empty() ? [] : args,
  }

  protocol.RequestAsync(ch, method, params, OnResponse)
  logger.LogDebug(printf('Request `%s`: %s', method, params->string()))
enddef
