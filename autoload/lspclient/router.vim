vim9script

import './core/protocol.vim'
import './features/language/goto_declaration.vim'
import './features/language/goto_definition.vim'
import './features/language/goto_implementation.vim'
import './features/language/goto_type_definition.vim'
import './features/language/publish_diagnostics.vim'
import './features/window/message.vim'
import './features/window/work_done.vim'
import './features/workspace/apply_edit.vim'
import './features/workspace/configuration.vim'
import './features/workspace/workspace_folders.vim'
import './logger.vim'

# Handle dynamic registrations issued by the server
def HandleRegisterCapabilityRequest(ch: channel, request: dict<any>, lspClientConfig: dict<any>): void
  const registrations = request.params.registrations

  for registration in registrations
    if registration.method == 'workspace/didChangeConfiguration'
      configuration.Register(ch, request, lspClientConfig)
    elseif registration.method == 'workspace/didChangeWorkspaceFolders'
      workspace_folders.Register(ch, request, lspClientConfig)
    elseif registration.method == 'textDocument/declaration'
      goto_declaration.Register(ch, registration, lspClientConfig)
    elseif registration.method == 'textDocument/definition'
      goto_definition.Register(ch, registration, lspClientConfig)
    elseif registration.method == 'textDocument/typeDefinition'
      goto_type_definition.Register(ch, registration, lspClientConfig)
    elseif registration.method == 'textDocument/implementation'
      goto_implementation.Register(ch, registration, lspClientConfig)
    endif
  endfor
enddef

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
    configuration.HandleRequest(ch, request, lspClientConfig)

    return
  endif

  if request.method == 'workspace/workspaceFolders'
    workspace_folders.HandleRequest(ch, request)

    return
  endif

  if request.method == 'textDocument/publishDiagnostics'
    publish_diagnostics.HandleRequest(request, lspClientConfig)

    return
  endif

  if request.method == 'client/registerCapability'
    HandleRegisterCapabilityRequest(ch, request, lspClientConfig)

    return
  endif

  # Window
  # --
  if request.method == 'window/showMessageRequest'
    message.HandleRequest(ch, request, lspClientConfig)

    return
  endif

  if request.method == 'window/showMessage' || request.method == 'window/logMessage'
    message.HandleNotification(request)

    return
  endif

  if request.method == 'window/workDoneProgress/create'
    work_done.HandleRequest(ch, request)

    return
  endif

  if request.method == 'workspace/applyEdit'
    apply_edit.HandleRequest(ch, request)

    return
  endif
enddef
