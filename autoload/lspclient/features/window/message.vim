vim9script

import '../../core/protocol.vim'
import '../../core/types.vim'
import '../../logger.vim'
import '../../vim/popup.vim'

const MessageType = types.MessageType

# Create confirm() {msg} format
const MakeConfirmMessage = (type: number, message: string): string =>
  printf('%s: %s', MessageType[type], message)

# Create confirm() {choices} format
const MakeConfirmActionChoices = (actions: list<any>): string =>
  actions->mapnew((i, val) => printf("&%s", val.title))->join("\n")

# Prompt user with an action choice via confirm() and then respond back to the
# LSP server with the selected action
export def HandleShowMessageRequest(ch: channel, request: any, lspClientConfig: dict<any>): void
  logger.LogDebug('Request `window/showMessageRequest`: ' .. request->string())

  const params = request.params
  const message = MakeConfirmMessage(params.type, params.message)
  const choices = MakeConfirmActionChoices(params.actions)

  var choiceId = confirm(message, choice, 1, MessageType[params.type])

  if choiceId == 0
    protocol.ResponseAsync(ch, request.id, {})
    logger.LogDebug('Response `window/showMessageRequest`: null')
  elseif choiceId > 0
    const selectedAction = params.actions[choiceId - 1]

    protocol.ResponseAsync(ch, request.id, selectedAction)
    logger.LogDebug('Response `window/showMessageRequest`: ' .. selectedAction->string())
  endif
enddef

export def HandleShowMessage(request: any): void
  const params = request.params
  logger.Print(MessageType[params.type], params.message)
  # popup.Notify(params.message, MessageType[params.type])
enddef

export def HandleLogMessage(request: any): void
  const params = request.params
  logger.Log(MessageType[params.type]->toupper(), params.message)
  # popup.Notify(params.message, MessageType[params.type])
enddef
