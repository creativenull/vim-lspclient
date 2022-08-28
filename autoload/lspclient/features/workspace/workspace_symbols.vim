vim9script

import '../../core/protocol.vim'
import '../../logger.vim'
import '../../random.vim'

const method = 'workspace/symbol'

def OnResponse(ch: channel, response: dict<any>): void
  logger.LogDebug(printf('Got Response `%s`: %s', method, response->string()))

  # Process results
  const result = response->get('result', [])

  if result->empty()
    return
  endif

  # WIP: Implementation
enddef

export def Request(ch: channel, query: string, context: dict<any>): void
  const params = {
    query: query,
    # workDoneToken: random.RandomStr(),
  }

  protocol.RequestAsync(ch, method, params, OnResponse)
  logger.LogDebug(printf('Request `%s`: %s', method, params->string()))
enddef
