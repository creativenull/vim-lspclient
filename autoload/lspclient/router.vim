vim9script

import './logger.vim'
import './core/protocol.vim'
import './features/workspace/configuration.vim'
import './features/window/message.vim'

export def HandleServerRequest(ch: channel, request: any, lspClientConfig: dict<any>): void
  if request.method == 'workspace/configuration'
    configuration.HandleConfigurationRequest(ch, request, lspClientConfig)
  endif

  if request.method == 'client/registerCapability'
    logger.LogInfo(request.method .. ' : ' .. request->string())
  endif

  # Window
  # --
  if request.method == 'window/showMessageRequest'
    message.HandleShowMessageRequest(ch, request, lspClientConfig)
  endif

  if request.method == 'window/showMessage'
    message.HandleShowMessage(request)
  endif

  if request.method == 'window/logMessage'
    message.HandleLogMessage(request)
  endif
enddef
