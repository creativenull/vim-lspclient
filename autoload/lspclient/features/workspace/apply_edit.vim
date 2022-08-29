vim9script

import '../../core/protocol.vim'
import '../../fs.vim'
import '../../logger.vim'

# Track lines that were add when `textEdit.newText` contains new lines
# ---
# Sometimes when `textEdit.newText` == '' but it happens after the previous
# `textEdit.newText` contained new lines in its content, setbufline() will
# set those lines too. But with empty string, this means that the line must
# be deleted and provides inconsistency from the LSP server.
var trackModifiedLines = []

# Set the contents into the buffer with a specified range and the new text
# to append/replace
def SetBufTextEdit(buf: number, textEdit: dict<any>): void
  const lineNum = textEdit.range.start.line + 1
  # const virtCol = textEdit.range.start.character + 1
  # const endLineNum = textEdit.range.end.line + 1
  # const endVirtCol = textEdit.range.end.character + 1
  # const col = buf->getbufline(lineNum->string())[0]->byteidx(virtCol)
  # const endCol = buf->getbufline(endLineNum->string())[0]->byteidx(endVirtCol)

  if textEdit.newText->empty()
    # Text deletion
    if trackModifiedLines->index(lineNum) == -1
      buf->deletebufline(lineNum)
    endif
  else
    # Text editing
    const containsNewLines = textEdit.newText->match("\n") != -1

    if containsNewLines
      # Use newlines to set for each line
      const lineContents = textEdit.newText->split("\n")
      lineContents->setbufline(buf, lineNum)

      # Track all except the current line
      var count = 1
      while count < lineContents->len()
        trackModifiedLines->add(lineNum + count)
        count += 1
      endwhile
    else
      textEdit.newText->setbufline(buf, lineNum)
    endif
  endif
enddef

# Apply edits given by the request
def ApplyEdits(params: dict<any>): bool
  var modified = false
  const changes = params.edit->get('changes', {})

  # For every document/file opened in vim
  if !changes->empty()
    for uri in changes->keys()
      const buf = fs.UriToBuffer(uri)
      const textEdits: list<any> = changes[uri]

      for textEdit in textEdits
        SetBufTextEdit(buf, textEdit)
      endfor
    endfor

    modified = true
    trackModifiedLines = []
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

        for textEdit in textEdits
          SetBufTextEdit(buf, textEdit)
        endfor
      endif
    endfor

    modified = true
    trackModifiedLines = []
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
