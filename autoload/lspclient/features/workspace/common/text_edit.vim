vim9script

import '../../../logger.vim'

# Set the contents into the buffer with a specified range and the new text
# to append/replace
def SetBufTextEdit(buf: number, textEdit: dict<any>): void
  const winId = buf->bufwinid()
  const lineNum = textEdit.range.start.line + 1
  const virtCol = textEdit.range.start.character + 1
  const endLineNum = textEdit.range.end.line + 1
  const endVirtCol = textEdit.range.end.character + 1

  const startResult = buf->getbufline(lineNum)
  const endResult = buf->getbufline(endLineNum)

  if startResult->empty() && endResult->empty() || !startResult->empty() && endResult->empty()
    # Add with new lines
    textEdit.newText->split("\n")->appendbufline(buf, lineNum)
  elseif !startResult->empty() && !endResult->empty()

    if textEdit.newText == ''
      buf->deletebufline(lineNum)
      return
    endif

    const col = startResult[0]->byteidx(virtCol)
    const endCol = endResult[0]->byteidx(endVirtCol)

    const lines = buf->getbufline(lineNum, endLineNum)
    const startPreserveText = lines[0][: col - 1]
    const endPreserveText = lines[-1][endCol - 1 :]

    # Ref: https://github.com/prabirshrestha/vim-lsp/blob/771755300a719ccfb78cd99c2ccd633871db3596/autoload/lsp/utils/text_edit.vim#L12
    var newTextLines = textEdit.newText->split("\n")
    newTextLines[0] = startPreserveText .. newTextLines[0]
    newTextLines[-1] = newTextLines[-1] .. endPreserveText

    if newTextLines->len() < lines->len()
      const newEndLineNum = lineNum + newTextLines->len()
      const emptyLines = lines->mapnew((i, val) => '')
      emptyLines->setbufline(buf, lineNum)
      newTextLines->setbufline(buf, lineNum)

      # Cleanup
      buf->deletebufline(newEndLineNum, endLineNum)
    elseif newTextLines->len() > lines->len()
      newTextLines->appendbufline(buf, lineNum)
    elseif newTextLines->len() == lines->len()
      newTextLines->setbufline(buf, lineNum)
    endif
  endif
enddef

export def ApplyBufTextEdits(buf: number, textEdits: list<any>): void
  if !buf->bufloaded()
    return
  endif

  try
    const sortedTextEdits = textEdits->copy()->sort((textEditA: dict<any>, textEditB: dict<any>): number => {
      const startA = textEditA.range.start
      const endA = textEditA.range.end
      const startB = textEditB.range.start
      const endB = textEditB.range.end

      const diff = startA.line - startB.line
      const isEqual = diff == 0

      if isEqual
        return startA.character - startB.character
      endif

      return startA.line - startB.line
    })

    for textEdit in sortedTextEdits
      SetBufTextEdit(buf, textEdit)
    endfor
  catch
    # NOP
  endtry
enddef
