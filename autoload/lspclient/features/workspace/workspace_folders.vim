vim9script

import '../../logger.vim'
import '../../fs.vim'
import '../../core/protocol.vim'

export def GetWorkspaceFolders(): list<any>
  return [
    {
      uri: fs.GetProjectRootUri(),
      name: fs.GetProjectRoot()->split('/')[-1],
    },
  ]
enddef

export def HandleRequest(ch: channel, request: any): void
  const result = GetWorkspaceFolders()
  protocol.ResponseAsync(ch, request.id, result)
  logger.LogDebug('Response workspace/workspaceFolders: ' .. result->string())
enddef

export def Register(ch: channel, request: any, lspClientConfig: dict<any>): void
  protocol.ResponseAsync(ch, request.id, {})
  logger.LogDebug('Response Successful Registration `workspace/didChangeWorkspaceFolders`')
enddef
