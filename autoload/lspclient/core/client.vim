vim9script

# Base functions to initialize and shutdown the LSP client

import '../features/workspace/workspace_folders.vim'
import '../fs.vim'
import '../logger.vim'
import './capabilities.vim'
import './protocol.vim'

const locale = 'en-US'
const clientInfo = {
  name: 'VIM',
  version: v:versionlong->string(),
}

# Request intialization of the client to the server
export def Initialize(
  ch: channel,
  opts = { lspClientConfig: null_dict, callback: null_function }
): void
  const clientCapabilities = capabilities.Make(opts.lspClientConfig.capabilities)
  const initializationOptions = opts.lspClientConfig.initOptions
  const params = {
    processId: getpid(),
    clientInfo: clientInfo,
    locale: locale,
    rootPath: null,
    rootUri: fs.GetProjectRootUri(),
    initializationOptions: initializationOptions,
    capabilities: clientCapabilities,
    trace: 'verbose',
    workspaceFolders: workspace_folders.GetWorkspaceFolders(),
  }

  protocol.RequestAsync(ch, 'initialize', params, opts.callback)

  logger.LogDebug('INITIALIZE rootUri: ' .. params.rootUri)
  logger.LogDebug('INITIALIZE workspaceFolders: ' .. params.workspaceFolders->string())
  logger.LogDebug('INITIALIZE clientCapabilities: ' .. clientCapabilities->string())
  logger.LogDebug('INITIALIZE initializationOptions: ' .. initializationOptions->string())
enddef

# Notify the server when client has initialized
export def Initialized(ch: channel): void
  protocol.NotifyAsync(ch, 'initialized')
  logger.LogInfo('LSP Initialized!')
enddef

# Notify the server when the client has exited
def OnShutdown(ch: channel, response: dict<any>): void
  if response->empty()
    logger.LogError('Empty Response')

    return
  endif

  if response->has_key('error')
    logger.LogError(response.error)

    return
  endif

  protocol.NotifyAsync(ch, 'exit')
  logger.LogInfo('LSP Exit')
enddef

# Request a client shutdown to the server
export def Shutdown(ch: channel): void
  protocol.RequestAsync(ch, 'shutdown', {}, OnShutdown)

  logger.LogInfo('LSP Issue Shutdown')
  logger.LogInfo('<======= LSP CLIENT LOG STOP =======>')
enddef
