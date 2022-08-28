vim9script

import '../../core/protocol.vim'
import '../../fs.vim'
import '../../logger.vim'
import '../../random.vim'

const requestMethod = 'workspace/symbol'
const resolveMethof = 'workspaceSymbol/resolve'

def OnResponse(ch: channel, response: dict<any>): void
  logger.LogDebug(printf('Got Response `%s`: %s', requestMethod, response->string()))

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

  protocol.RequestAsync(ch, requestMethod, params, OnResponse)
  logger.LogDebug(printf('Request `%s`: %s', requestMethod, params->string()))
enddef

def OnResolveResponse(ch: channel, response: dict<any>): void
  logger.LogDebug(printf('Got Response `%s`: %s', resolveMethod, response->string()))

  # Process results
  const result = response->get('result', {})

  if result->empty()
    return
  endif

  # WIP: Implementation
enddef

export def ResolveRequest(ch: channel, params: dict<any>, context: dict<any>): void
  protocol.RequestAsync(ch, resolveMethod, params, OnResolveResponse)
  logger.LogDebug(printf('Request `%s`: %s', resolveMethod, params->string()))
enddef
