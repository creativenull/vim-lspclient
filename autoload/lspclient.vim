vim9script

import './lspclient/core/client.vim'
import './lspclient/core/document.vim'
import './lspclient/fs.vim'
import './lspclient/logger.vim'
import './lspclient/router.vim'
import './lspclient/config.vim'
import './lspclient/features/language/code_lens.vim'
import './lspclient/features/language/document_symbols.vim'
import './lspclient/features/language/goto_declaration.vim'
import './lspclient/features/language/goto_definition.vim'
import './lspclient/features/language/goto_type_definition.vim'
import './lspclient/features/language/goto_implementation.vim'
import './lspclient/features/language/references.vim'
import './lspclient/features/language/document_highlight.vim'
import './lspclient/features/language/hover.vim'
import './lspclient/features/workspace/workspace_symbols.vim'
import './lspclient/features/workspace/execute_command.vim'
import './lspclient/vim/popup.vim'

# Events
const openBufEvents = ['BufReadPost']
const changeBufEvents = ['TextChanged']
const closeBufEvents = ['BufDelete']
const willSaveBufEvents = ['BufWritePre']
const didSaveBufEvents = ['BufWrite']

# interface LspClient {
#   id: number
#   ready: bool
#   group: string
#   config: dict<any>
#   job: job
#   channel: channle
#   documents: list<any>
#   serverCapabilities: dict<any>
# }
var lspClients = {}

# LspClient property access
# ---

def GetChannel(id: string): channel
  return lspClients[id].channel
enddef

def SetChannel(id: string, newValue: channel): void
  lspClients[id].channel = newValue
enddef

def GetJob(id: string): job
  return lspClients[id].job
enddef

def SetJob(id: string, newValue: job): void
  lspClients[id].job = newValue
enddef

def GetConfig(id: string): dict<any>
  return lspClients[id].config
enddef

def GetEventGroup(id: string): string
  return lspClients[id].group
enddef

def GetDocuments(id: string): list<any>
  return lspClients[id].documents
enddef

def GetServerCapabilities(id: string): dict<any>
  return lspClients[id].serverCapabilities
enddef

def TrackDocument(id: string, newValue: dict<any>): void
  lspClients[id].documents->add(newValue)
enddef

def RemoveDocument(id: string, buf: number): dict<any>
  const result = GetDocuments(id)->copy()->filter((i, val) => val.bufnr == buf)
  GetDocuments(id)->filter((i, val) => val.bufnr != buf)

  if !result->empty()
    return result[0]
  endif

  return null_dict
enddef

def LSPClientIsAttachedToBuffer(id: string, buf: number): bool
  const results = filter(GetDocuments(id)->copy(), (i, val) => val.bufnr == buf)
  return !results->empty()
enddef

def IsChannelConnected(ch: channel): bool
  return ch->ch_status() == 'open'
enddef

def LSPClientIsReady(id: string, buf: number): bool
  return lspClients[id].ready && LSPClientIsAttachedToBuffer(id, buf)
enddef

# Language Features
# ---

# Make a callback for every client attached to a buffer
def RequestFeatureForEachClient(Callback: func, serverCapability: string): void
  const buf = bufnr()
  const registeredClients = lspClients->keys()

  if registeredClients->empty()
    return
  endif

  for clientId in registeredClients
    if !IsChannelConnected(GetChannel(clientId))
      continue
    endif

    const serverCapabilities = GetServerCapabilities(clientId)
    if !serverCapabilities->has_key(serverCapability)
      const [_, startIdx, _] = serverCapability->matchstrpos('Provider')
      const providerName = serverCapability[0 : startIdx - 1]
      const clientName = GetConfig(clientId).name

      popup.Notify(printf('%s: no support for `%s`', clientName, providerName), popup.SeverityType.I)

      continue
    endif

    if LSPClientIsReady(clientId, buf)
      const popupLoadingRef = popup.LoadingStart()
      Callback(GetChannel(clientId), buf, { popupLoadingRef: popupLoadingRef })

      # TODO: For now just run request for the first client attached, try to
      # find ways to handle for multiple servers, eg tsserver + diagnosticls
      break
    endif
  endfor
enddef

export def GotoDeclaration(): void
  RequestFeatureForEachClient(goto_declaration.Request, 'declarationProvider')
enddef

export def GotoDefinition(): void
  RequestFeatureForEachClient(goto_definition.Request, 'definitionProvider')
enddef

export def GotoTypeDefinition(): void
  RequestFeatureForEachClient(goto_type_definition.Request, 'typeDefinitionProvider')
enddef

export def GotoImplementation(): void
  RequestFeatureForEachClient(goto_implementation.Request, 'implementationProvider')
enddef

export def FindReferences(): void
  RequestFeatureForEachClient(references.Request, 'referencesProvider')
enddef

export def ReferenceNext(): void
  try
    lnext
  catch
    lfirst
  endtry
enddef

export def ReferencePrev(): void
  try
    lprev
  catch
    llast
  endtry
enddef

export def DocumentHighlight(): void
  RequestFeatureForEachClient(document_highlight.Request, 'documentHighlightProvider')
enddef

export def DocumentHighlightClear(): void
  document_highlight.Clear()
enddef

export def Hover(): void
  RequestFeatureForEachClient(hover.Request, 'hoverProvider')
enddef

export def CodeLens(): void
  RequestFeatureForEachClient(code_lens.Request, 'codeLensProvider')
enddef

export def DocumentSymbols(): void
  RequestFeatureForEachClient(document_symbols.Request, 'documentSymbolProvider')
enddef

export def FoldingRange(): void
  RequestFeatureForEachClient(folding_range.Request, 'foldingRangeProvider')
enddef

export def DiagnosticPopupAtCursor(): void
  const [_, cursorLineNum, cursorCol, _, _] = getcurpos()
  const buf = bufnr('%')
  const qflist = getqflist()

  if qflist->empty()
    return
  endif

  for item in qflist
    if item.bufnr == buf && item.lnum == cursorLineNum && (cursorCol >= item.col && cursorCol <= item.end_col)
      const hasLines = item.text->match("\n") != -1
      const content = hasLines ? item.text->split("\n") : item.text
      popup.Cursor(content, popup.SeverityType[item.type])
    endif
  endfor
enddef

export def Diagnostics(): void
  const buf = bufnr()
  const listSize = getqflist()->len()

  if listSize == 0
    return
  endif

  execute printf('copen %d', listSize > 10 ? 10 : listSize)
enddef

# TODO: ensure :lnext doesn't print to :messages
export def DiagnosticNext(): void
  try
    cnext
    # lspclient.DiagnosticPopupAtCursor()
  catch
    cfirst
  endtry
enddef

# TODO: ensure :lprev doesn't print to :messages
export def DiagnosticPrev(): void
  try
    cprev
    # lspclient.DiagnosticPopupAtCursor()
  catch
    clast
  endtry
enddef

# Workspace Features
# ---

def RequestWorkspaceForEachClient(Callback: func, serverCapability: string): void
  const buf = bufnr()
  const registeredClients = lspClients->keys()

  if registeredClients->empty()
    return
  endif

  for clientId in registeredClients
    if !IsChannelConnected(GetChannel(clientId))
      continue
    endif

    const serverCapabilities = GetServerCapabilities(clientId)
    if !serverCapabilities->has_key(serverCapability)
      const [_, startIdx, _] = serverCapability->matchstrpos('Provider')
      const providerName = serverCapability[0 : startIdx - 1]
      const clientName = GetConfig(clientId).name

      popup.Notify(printf('%s: no support for `%s`', clientName, providerName), popup.SeverityType.I)

      continue
    endif

    if LSPClientIsReady(clientId, buf)
      Callback(GetChannel(clientId), { lspClientConfig: GetConfig(clientId) })

      # TODO: For now just run request for the first client attached, try to
      # find ways to handle for multiple servers, eg tsserver + diagnosticls
      break
    endif
  endfor
enddef

export def WorkspaceSymbols(query: string): void
  RequestWorkspaceForEachClient((ch: channel, context: dict<any>) => {
    workspace_symbols.Request(ch, query, context)
  }, 'workspaceSymbolProvider')
enddef

export def ExecuteCommand(rawInput: string): void
  if rawInput->empty()
    return
  endif

  const inputList = rawInput->split(' ')
  const cmd = inputList[0]
  var args = []

  # Collect arguments
  if inputList->len() > 1
    for i in range(1, inputList->len() - 1)
      args->add(inputList[i])
    endfor
  endif

  RequestWorkspaceForEachClient((ch, context) => {
    execute_command.Request(ch, cmd, args, context)
  }, 'executeCommandProvider')
enddef

# Buffer/Document sync
# ---

export def DocumentDidOpen(id: string): void
  const buf = bufnr()
  const ft = buf->getbufvar('&filetype')
  const isFileType = GetConfig(id).filetypes->index(ft) != -1

  if !isFileType
    return
  endif

  document.NotifyDidOpen(GetChannel(id), buf)

  # Track this document lifecycle, include any other refs
  TrackDocument(id, { bufnr: buf })

  # Subscribe to buffer events until closed
  const textDocumentSync = GetServerCapabilities(id)->get('textDocumentSync', {})
  var documentEvents = [
    {
      group: GetEventGroup(id),
      event: changeBufEvents,
      bufnr: buf,
      cmd: printf('call lspclient#DocumentDidChange("%s", %d)', id, buf)
    },
    {
      group: GetEventGroup(id),
      event: closeBufEvents,
      bufnr: buf,
      cmd: printf('call lspclient#DocumentDidClose("%s", %d)', id, buf)
    },
  ]

  # Enable extra document features, if available by the server capabilities
  if textDocumentSync->type() == v:t_dict
    if textDocumentSync->get('willSave', false)
      documentEvents->add({
        group: GetEventGroup(id),
        event: willSaveBufEvents,
        bufnr: buf,
        cmd: printf('call lspclient#DocumentWillSave("%s", %d)', id, buf)
      })
    endif

    const didSave = textDocumentSync->get('save')
    if didSave->type() == v:t_dict && !didSave->empty() && didSave->get('includeText', false)
      # Only include text if: it's a dict, not empty dict, and didSave.includeText is true
      documentEvents->add({
        group: GetEventGroup(id),
        event: didSaveBufEvents,
        bufnr: buf,
        cmd: printf('call lspclient#DocumentDidSave("%s", %d, v:true)', id, buf)
      })
    elseif (didSave->type() == v:t_bool || didSave->type() == v:t_number) && didSave
      documentEvents->add({
        group: GetEventGroup(id),
        event: didSaveBufEvents,
        bufnr: buf,
        cmd: printf('call lspclient#DocumentDidSave("%s", %d)', id, buf)
      })
    endif
  endif

  autocmd_add(documentEvents)
enddef

export def DocumentDidChange(id: string, buf: number): void
  if !buf->getbufvar('&modified')
    return
  endif

  document.NotifyDidChange(GetChannel(id), buf)
enddef

export def DocumentDidClose(id: string, buf: number): void
  # Unsubscribe from changes and events
  RemoveDocument(id, buf)
  autocmd_delete([
    { group: GetEventGroup(id), event: changeBufEvents, bufnr: buf },
    { group: GetEventGroup(id), event: closeBufEvents, bufnr: buf },
  ])
  
  document.NotifyDidClose(GetChannel(id), buf)
enddef

export def DocumentWillSave(id: string, buf: number): void
  if !buf->getbufvar('&modified')
    return
  endif

  document.NotifyWillSave(GetChannel(id), buf)
enddef

export def DocumentDidSave(id: string, buf: number, includeText = false): void
  if !buf->getbufvar('&modified')
    return
  endif

  document.NotifyDidSave(GetChannel(id), buf, includeText)
enddef

# LSP Server functions
# ---

export def LspStartServer(id: string): void
  if IsChannelConnected(GetChannel(id))
    return
  endif

  if !fs.HasRootMarker(GetConfig(id).markers)
    return
  endif

  # Notify the server that the client has initialized once
  # the response provides no errors
  def OnInitialize(ch: channel, response: dict<any>): void
    var errmsg = ''

    if response->empty()
      errmsg = 'Empty Response'
      logger.LogError(errmsg)

      return
    endif

    if response->has_key('error')
      errmsg = response.error->string()
      logger.LogError(errmsg)

      return
    endif

    # Store server capabilities
    lspClients[id].serverCapabilities = response.result.capabilities
    logger.LogDebug('SERVER CAPABILITIES: ' .. response->string())

    client.Initialized(ch)

    # Open the current document
    DocumentDidOpen(id)

    # Ready the server
    lspClients[id].ready = true
    logger.PrintInfo('LSP Ready: ' .. GetConfig(id).name)

    # Let future buffers know about the open document event
    autocmd_add([
      {
        group: GetEventGroup(id),
        event: openBufEvents,
        pattern: '*',
        cmd: printf('call lspclient#DocumentDidOpen("%s")', id),
      },
    ])
  enddef

  def OnStdout(ch: channel, data: any): void
    router.HandleServerRequest(ch, data, GetConfig(id))
  enddef

  def OnStderr(ch: channel, data: any): void
    logger.LogError('STDERR : ' .. data->string())
  enddef

  def OnExit(jb: job, status: any): void
    logger.LogDebug('Job Exiting')
  enddef

  const jobOpts = {
    in_mode: 'lsp',
    out_mode: 'lsp',
    err_mode: 'nl',
    out_cb: OnStdout,
    err_cb: OnStderr,
    exit_cb: OnExit,
  }

  const lspClientConfig = GetConfig(id)

  logger.LogInfo('<======= LSP CLIENT LOG START =======>')
  logger.LogInfo('Starting LSP Server: ' .. lspClientConfig.name)

  const job = job_start(lspClientConfig.cmd, jobOpts)
  const channel = job_getchannel(job)

  SetJob(id, job)
  SetChannel(id, channel)

  # Start the initialization process
  client.Initialize(GetChannel(id), {
    lspClientConfig: lspClientConfig,
    callback: OnInitialize,
  })
enddef

export def LspStopServer(id: string): void
  if !IsChannelConnected(GetChannel(id))
    return
  endif

  client.Shutdown(GetChannel(id))
enddef

export def Create(partialLspClientConfig: dict<any>): void
  # Merge and validate the client config and fail the setup
  # if invalidated
  const lspClientConfig = config.MergeLspClientConfig(partialLspClientConfig)

  const errmsg = config.ValidateLspClientConfig(lspClientConfig)
  if !errmsg->empty()
    logger.PrintError(errmsg)
    logger.LogError(errmsg)

    return
  endif

  const id = lspClientConfig.name
  var lspClient = {
    id: id,
    ready: false,
    group: printf('LspClient_%s', id),
    config: lspClientConfig,
    job: null_job,
    channel: null_channel,
    documents: [],
    serverCapabilities: null_dict,
  }

  # Add to a 'global' state
  lspClients[id] = lspClient

  execute printf('augroup %s', GetEventGroup(id))
  autocmd_add([
    {
      group: GetEventGroup(id),
      event: 'FileType',
      pattern: GetConfig(id).filetypes,
      cmd: printf('call lspclient#LspStartServer("%s")', id),
    },
    {
      group: GetEventGroup(id),
      event: 'VimLeavePre',
      pattern: '*',
      cmd: printf('call lspclient#LspStopServer("%s")', id),
    },
  ])
enddef

export def Info(): void
  const servers = lspClients->keys()

  if servers->empty()
    logger.PrintInfo('No servers registered.')
  else
    logger.PrintInfo('Registered servers: ' .. servers->join(','))
  endif
enddef
