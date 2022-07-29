vim9script

import '../../logger.vim'
import '../../core/protocol.vim'

export def HandleConfigurationRequest(ch: channel, request: any, lspClientConfig: dict<any>): void
  proto.ResponseAsync(ch, request.id, [lspClientConfig.config])
  logger.LogInfo('Response workspace/configuration: ' .. lspClientConfig.config->string())
enddef

export def NotifyDidChangeConfiguration(ch: channel, lspClientConfig: any): void
  proto.NotifyAsync(ch, 'workspace/didChangeConfiguration', { settings: lspClientConfig.config })
  logger.LogInfo('Notify workspace/didChangeConfiguration: ' .. lspClientConfig.config->string())
enddef
