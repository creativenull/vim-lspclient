vim9script

# Handle document synchronization between the editor and the server
# this includes opening and closing the file, and modifying the file in
# buffer.

# interface Document {
#   filepath?: string;
#   filetype?: string;
#   changes?: list<any>;
#   version: number;
#   contents: string;
# }

import '../fs.vim'
import '../logger.vim'
import './protocol.vim'

# Notify LSP server on file/buffer open
export def NotifyDidOpen(ch: channel, document: dict<any>): void
  protocol.NotifyAsync(ch, 'textDocument/didOpen', {
    textDocument: {
      uri: document.uri,
      languageId: document.filetype,
      version: document.version,
      text: document.contents,
    },
  })
  logger.LogInfo(printf('Open Document: (uri: %s)', document.uri))
enddef

# Notify LSP server on file/buffer change
export def NotifyDidChange(ch: channel, document: dict<any>): void
  protocol.NotifyAsync(ch, 'textDocument/didChange', {
    textDocument: {
      uri: document.uri,
      version: document.version,
    },
    contentChanges: document.changes,
  })
  logger.LogInfo(printf('Change Document: (uri: `%s`)', document.uri))
  # logger.LogInfo('Change Document Changes: ' .. document.changes->string())
enddef

# Notify LSP server when a file/buffer is closed
export def NotifyDidClose(ch: channel, document: dict<any>): void
  protocol.NotifyAsync(ch, 'textDocument/didClose', {
    textDocument: { uri: document.uri },
  })
  logger.LogInfo(printf('Close Document: (uri: `%s`)', document.uri))
enddef

# Let LSP server know when the document is being saved to the filesystem
export def NotifyWillSave(ch: channel, document: dict<any>): void
  protocol.NotifyAsync(ch, 'textDocument/willSave', {
    textDocument: { uri: document.uri },
    reason: 1, # Manually
  })
  logger.LogInfo(printf('WillSave Document: (uri: `%s`)', document.uri))
enddef

# Let LSP server know when the document has been saved to the filesystem
export def NotifyDidSave(ch: channel, document: dict<any>): void
  var params = {
    textDocument: { uri: document.uri },
  }

  # Optionally include text provided by server capabilities
  if document->get('text', null)
    params.text = document.text
  endif

  protocol.NotifyAsync(ch, 'textDocument/didSave', params)
  logger.LogInfo(printf('DidSave Document: (uri: `%s`)', document.uri))
enddef
