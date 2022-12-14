vim9script

import '../../core/protocol.vim'
import '../../fs.vim'
import '../../logger.vim'
import '../../random.vim'
import '../../vim/popup.vim'

const method = 'textDocument/hover'

const PopupLevel = popup.Level
var popupLoadingRef = {}

def OnResponse(ch: channel, response: any): void
  logger.LogDebug(printf('Got Response `%s`: %s', method, response->string()))

  # Clear loading window
  if !popupLoadingRef->empty()
    popup.LoadingStop(popupLoadingRef)
  endif

  const result = response->get('result', {})

  if result->empty()
    return
  endif

  const contents = result.contents
  var languageId = ''

  if contents->type() == v:t_string
    # string
    popup.Cursor(contents, PopupLevel.Hover)
  endif

  if contents->type() == v:t_list
    var popupContents = []

    # MarkupString[] type
    for item in contents
      if item->type() == v:t_dict
        # Check if there are \n in the text
        # split and add individually
        if item.value->match("\n") != -1
          const values = item.value->split("\n")
          for val in values
            popupContents->add(val)
          endfor

          continue
        else
          popupContents->add(item.value)
        endif

        if item->has_key('language')
          languageId = item.language
        endif
      else
        if !item->empty()
          # Check if there are \n in the text
          # split and add individually
          if item->match("\n") != -1
            const values = item->split("\n")
            for val in values
              popupContents->add(val)
            endfor

            continue
          else
            popupContents->add(item)
          endif
        endif
      endif
    endfor

    const winId = popup.Cursor(popupContents, PopupLevel.Hover, { maxheight: 5 })

    # WIP: Set a custom filetype for documentation
    # if !languageId->empty() && winId != -1
    #   setbufvar(winId->winbufnr(), '&filetype', languageId)
    # endif
  endif

  if contents->type() == v:t_dict
    if !contents->has_key('language')
      # MarkupString type
      var markupContents = []

      if contents.value->match("\n") != -1
        const values = contents.value->split("\n")

        for val in values
          markupContents->add(val)
        endfor

        popup.Cursor(markupContents, PopupLevel.Hover)
      else
        popup.Cursor(contents.value, PopupLevel.Hover)
      endif
    endif

    if !contents->has_key('kind')
      # MarkupContent type
      var markupContents = []

      if contents.value->match("\n") != -1
        const values = contents.value->split("\n")

        for val in values
          markupContents->add(val)
        endfor

        popup.Cursor(markupContents, PopupLevel.Hover)
      else
        popup.Cursor(contents.value, PopupLevel.Hover)
      endif
    endif
  endif
enddef

export def Request(ch: channel, buf: number, context: dict<any>): void
  popupLoadingRef = context->get('popupLoadingRef', {})
  const winId = bufwinid(buf)
  const [_, line, col, _, _] = getcurpos(winId)
  const params = {
    textDocument: { uri: fs.BufferToUri(buf) },
    position: {
      line: line - 1,
      character: col - 1,
    },
    # workDoneToken: random.RandomStr(),
    # partialResultToken: '',
  }

  protocol.RequestAsync(ch, method, params, OnResponse)
  logger.LogDebug(printf('Request `%s`: %s', method, params->string()))
enddef
