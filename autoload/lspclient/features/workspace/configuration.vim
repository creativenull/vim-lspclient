vim9script

import '../../logger.vim'
import '../../core/protocol.vim'

export def HandleConfigurationRequest(ch: channel, request: any, lspClientConfig: dict<any>): void
  protocol.ResponseAsync(ch, request.id, [lspClientConfig.config])
  logger.LogDebug('Response `workspace/configuration`: ' .. lspClientConfig.config->string())
enddef

export def Register(ch: channel, request: any, lspClientConfig: dict<any>): void
  def NotifyChange(_timerId: any): void
    protocol.NotifyAsync(ch, 'workspace/didChangeConfiguration', { settings: lspClientConfig.config })
    logger.LogDebug('Notify `workspace/didChangeConfiguration`: ' .. lspClientConfig.config->string())
  enddef

  protocol.ResponseAsync(ch, request.id)
  logger.LogDebug('Response Successful Registration `workspace/didChangeConfiguration`')

  # Send a didChangeConfiguration notif after some time
  timer_start(2000, NotifyChange)
enddef
