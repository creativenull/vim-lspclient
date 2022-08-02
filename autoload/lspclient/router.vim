vim9script

import './logger.vim'
import './core/protocol.vim'
import './features/language/goto_declaration.vim'
import './features/language/goto_definition.vim'
import './features/language/publish_diagnostics.vim'
import './features/workspace/configuration.vim'
import './features/workspace/workspace_folders.vim'
import './features/window/message.vim'

export def HandleServerRequest(ch: channel, request: any, lspClientConfig: dict<any>): void
  if request.method == 'workspace/configuration'
    configuration.HandleConfigurationRequest(ch, request, lspClientConfig)
  endif

  if request.method == 'workspace/workspaceFolders'
    workspace_folders.HandleWorkspaceFoldersRequest(ch, request)
  endif

  if request.method == 'textDocument/publishDiagnostics'
    publish_diagnostics.HandlePublishDiagnosticsNotification(request, lspClientConfig)
  endif

  if request.method == 'client/registerCapability'
    logger.LogInfo(request.method .. ' : ' .. request->string())
    const registrations = request.params.registrations

    # Handle dynamicRegistration requests
    for registration in registrations->copy()
      if registration.method == 'workspace/didChangeConfiguration'
        configuration.NotifyDidChangeConfiguration(ch, lspClientConfig)
      endif

      if registration.method == 'textDocument/declaration'
        goto_declaration.HandleGotoDeclarationRegistration(ch, registration, lspClientConfig)
      endif

      if registration.method == 'textDocument/definition'
        goto_definition.HandleGotoDefinitionRegistration(ch, registration, lspClientConfig)
      endif
    endfor
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
