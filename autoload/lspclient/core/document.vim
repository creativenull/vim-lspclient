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
export def NotifyDidOpen(ch: channel, buf: number): void
  const params = {
    textDocument: {
      uri: fs.BufferToUri(buf),
      languageId: buf->getbufvar('&filetype'),
      version: buf->getbufvar('changedtick'),
      text: fs.GetBufferContents(buf),
    },
  }

  protocol.NotifyAsync(ch, 'textDocument/didOpen', params)
  logger.LogDebug(printf('Open Document: (uri: `%s`)', params.textDocument.uri))
enddef

# Notify LSP server on file/buffer change
# TODO: Figure out a way to be able to create diffs instead of
#       sending the entire buffer.
#
#       Possible solutions:
#         + Implement Myers's O(ND) algorithm (caveat: need time to learn it)
#         + Use listener_add() to provided changes (caveat: only works on insert mode, might need to debounce)
export def NotifyDidChange(ch: channel, buf: number): void
  const params = {
    textDocument: {
      uri: fs.BufferToUri(buf),
      version: buf->getbufvar('changedtick'),
    },
    contentChanges: [{ text: fs.GetBufferContents(buf) }],
  }

  protocol.NotifyAsync(ch, 'textDocument/didChange', params)
  logger.LogDebug(printf('Change Document: (uri: `%s`)', params.textDocument.uri))
enddef

# Notify LSP server when a file/buffer is closed
export def NotifyDidClose(ch: channel, buf: number): void
  const params = {
    textDocument: { uri: fs.BufferToUri(buf) },
  }

  protocol.NotifyAsync(ch, 'textDocument/didClose', params)
  logger.LogDebug(printf('Close Document: (uri: `%s`)', params.textDocument.uri))
enddef

# Let LSP server know when the document is being saved to the filesystem
export def NotifyWillSave(ch: channel, buf: number): void
  const params = {
    textDocument: { uri: fs.BufferToUri(buf) },
    reason: 1, # Manually
  }

  protocol.NotifyAsync(ch, 'textDocument/willSave', params)
  logger.LogDebug(printf('WillSave Document: (uri: `%s`)', params.textDocument.uri))
enddef

# Let LSP server know when the document has been saved to the filesystem
export def NotifyDidSave(ch: channel, buf: number, includeText = false): void
  var params = {
    textDocument: { uri: fs.BufferToUri(buf) },
  }

  # Optionally include text provided by server capabilities
  if includeText
    params.text = fs.GetBufferContents(buf)
  endif

  protocol.NotifyAsync(ch, 'textDocument/didSave', params)
  logger.LogDebug(printf('DidSave Document: (uri: `%s`)', params.textDocument.uri))
enddef
