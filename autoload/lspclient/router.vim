vim9script

import './core/protocol.vim'
import './features/language/goto_declaration.vim'
import './features/language/goto_definition.vim'
import './features/language/goto_implementation.vim'
import './features/language/goto_type_definition.vim'
import './features/language/publish_diagnostics.vim'
import './features/window/message.vim'
import './features/window/work_done.vim'
import './features/workspace/configuration.vim'
import './features/workspace/workspace_folders.vim'
import './logger.vim'

export def HandleServerRequest(ch: channel, request: dict<any>, lspClientConfig: dict<any>): void
  if request->has_key('error')
    logger.LogError(request->string())
    logger.PrintError(printf('[code: %d] `%s`', request.error.code, request.error.message))

    return
  endif

  if !request->has_key('method')
    return
  endif

  logger.LogDebug('STDOUT: ' .. request->string())

  if request.method == 'workspace/configuration'
    configuration.HandleConfigurationRequest(ch, request, lspClientConfig)

    return
  endif

  if request.method == 'workspace/workspaceFolders'
    workspace_folders.HandleWorkspaceFoldersRequest(ch, request)

    return
  endif

  if request.method == 'textDocument/publishDiagnostics'
    publish_diagnostics.HandleRequest(request, lspClientConfig)

    return
  endif

  if request.method == 'client/registerCapability'
    const registrations = request.params.registrations

    # Handle dynamicRegistration requests
    for registration in registrations->copy()
      if registration.method == 'workspace/didChangeConfiguration'
        configuration.Register(ch, request, lspClientConfig)
      endif

      if registration.method == 'textDocument/declaration'
        goto_declaration.Register(ch, registration, lspClientConfig)
      endif

      if registration.method == 'textDocument/definition'
        goto_definition.Register(ch, registration, lspClientConfig)
      endif

      if registration.method == 'textDocument/typeDefinition'
        goto_type_definition.Register(ch, registration, lspClientConfig)
      endif

      if registration.method == 'textDocument/implementation'
        goto_implementation.Register(ch, registration, lspClientConfig)
      endif
    endfor
  endif

  # Window
  # --
  if request.method == 'window/showMessageRequest'
    message.HandleShowMessageRequest(ch, request, lspClientConfig)

    return
  endif

  if request.method == 'window/showMessage'
    message.HandleShowMessage(request)

    return
  endif

  if request.method == 'window/logMessage'
    message.HandleLogMessage(request)

    return
  endif

  if request.method == 'window/workDoneProgress/create'
    work_done.Create(ch, request)

    return
  endif
enddef
