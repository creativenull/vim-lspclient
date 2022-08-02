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

export def HandleWorkspaceFoldersRequest(ch: channel, request: any): void
  const result = GetWorkspaceFolders()
  protocol.ResponseAsync(ch, request.id, result)
  logger.LogInfo('Response workspace/workspaceFolders: ' .. result->string())
enddef

def HandleDidChangeWorkspaceFoldersRequest(ch: channel, request: any): void

enddef
