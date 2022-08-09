vim9script

# The generic protocol to be used by the LSP client to send messages to the LSP
# server, whether it's sync or async for Requests, Notifications and Responses
# back to the server.

import '../logger.vim'

# Send a sync request to the LSP server
# Method is required
# Params are optional
export def Request(ch: channel, method: string, params = null_dict): dict<any>
  if ch->ch_status() != 'open'
    throw logger.Error('Channel not open')
  endif

  const request = { method: method, params: params }
  const chOpts = { timeout: 500 }

  return ch->ch_evalexpr(request, chOpts)
enddef

# Send an async request to the LSP server
# Method is required
# Params and Callback are optional
export def RequestAsync(ch: channel, method: string, params = null_dict, callback = null_function): void
  if ch->ch_status() != 'open'
    throw logger.Error('Channel not open')
  endif

  const request = { method: method, params: params }
  const chOpts = { callback: callback }

  ch->ch_sendexpr(request, chOpts)
enddef

# Send a notification request to the LSP server
# Method is required
# Params are optional
export def NotifyAsync(ch: channel, method: string, params = null_dict): void
  if ch->ch_status() != 'open'
    throw logger.Error('Channel not open')
  endif

  const request = { method: method, params: params }
  ch->ch_sendexpr(request)
enddef

# Handle generic response back to LSP server
# RequestID is required
# Result and Error are optional
export def ResponseAsync(ch: channel, requestId: any, result: any, error = null_dict): void
  var response = { id: requestId }

  if !result->empty() && error->empty()
    response.result = result
  elseif result->empty() && !error->empty()
    response.error = error
  elseif result->empty() && error->empty()
    # Successful response, but with empty result
    response.result = result
  else
    throw 'Invalid response to server'
  endif

  ch->ch_sendexpr(response)
enddef
