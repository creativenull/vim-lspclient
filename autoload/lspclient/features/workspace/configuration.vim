vim9script

import '../../core/log.vim'
import '../../core/protocol.vim'

export def HandleConfigurationRequest(ch: channel, request: any, lspClientConfig: dict<any>): void
  proto.ResponseAsync(ch, request.id, [lspClientConfig.config])
  log.LogInfo('Response workspace/configuration: ' .. lspClientConfig.config->string())
enddef

export def NotifyDidChangeConfiguration(ch: channel, lspClientConfig: any): void
  proto.NotifyAsync(ch, 'workspace/didChangeConfiguration', { settings: lspClientConfig.config })
  log.LogInfo('Notify workspace/didChangeConfiguration: ' .. lspClientConfig.config->string())
enddef
