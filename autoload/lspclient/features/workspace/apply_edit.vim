vim9script

import '../../core/protocol.vim'
import '../../fs.vim'
import '../../logger.vim'
import './common/text_edit.vim'

# Apply edits given by the request
def ApplyEdits(params: dict<any>): bool
  var modified = false
  const changes = params.edit->get('changes', {})

  # For every document/file opened in vim
  if !changes->empty()
    for uri in changes->keys()
      const buf = fs.UriToBuffer(uri)
      const textEdits: list<any> = changes[uri]
      text_edit.ApplyBufTextEdits(buf, textEdits)
    endfor

    modified = true
  endif

  if modified
    # No need to make changes via `documentChanges`, if `changes` has
    # done the modifications
    return true
  endif

  # Single document/file
  const documentChanges = params.edit->get('documentChanges', [])

  if !documentChanges->empty()
    for documentChange in documentChanges
      const hasKind = !documentChange->get('kind', '')->empty()

      if hasKind
        # TODO: Handle create/rename/deletion of files
      else
        # Handle textEdits instead
        const buf = fs.UriToBuffer(documentChange.textDocument.uri)
        const textEdits = documentChanges.edits
        text_edit.ApplyBufTextEdits(buf, textEdits)
      endif
    endfor

    modified = true
  endif

  return modified
enddef

export def HandleRequest(ch: channel, request: dict<any>): void
  const params = request->get('params', {})

  if params->empty()
    return
  endif

  # TODO: Make this async
  const applied = ApplyEdits(params)

  const result = {
    applied: applied,
    failureReason: !applied ? 'Failed to make changes to the document/buffer' : null,
  }

  protocol.ResponseAsync(ch, request.id, result)
  logger.LogDebug('Response `workspace/applyEdit`: ' .. result->string())
enddef
