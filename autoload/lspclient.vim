vim9script

import './lspclient/core/client.vim'
import './lspclient/core/document.vim'
import './lspclient/fs.vim'
import './lspclient/logger.vim'
import './lspclient/router.vim'
import './lspclient/config.vim'
import './lspclient/features/language/goto_declaration.vim'
import './lspclient/features/language/goto_definition.vim'

# Events
const openBufEvents = ['BufReadPost']
const changeBufEvents = ['TextChanged']
const closeBufEvents = ['BufDelete']
const willSaveBufEvents = ['BufWritePre']
const didSaveBufEvents = ['BufWrite']

# interface LspClient {
#   id: number
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

def IsAttachedToBuffers(id: string, buf: number): bool
  const results = filter(GetDocuments(id)->copy(), (i, val) => val.bufnr == buf)
  return !results->empty()
enddef

def IsChannelConnected(ch: channel): bool
  return ch->ch_status() == 'open'
enddef

# Language Features
# ---

# Make a callback for every client attached to a buffer
def RequestForEachClient(Callback: func): void
  const buf = bufnr('%')
  const registeredClients = lspClients->keys()

  if registeredClients->empty()
    return
  endif

  for clientId in registeredClients
    if IsAttachedToBuffers(clientId, buf)
      Callback(GetChannel(clientId), buf)
    endif
  endfor
enddef

export def GotoDeclaration(): void
  def OnRequest(ch: channel, buf: number): void
    const curpos = getcurpos()
    const line = curpos[1]
    const col = curpos[2]
    const doc = {
      uri: fs.ProjectFileToUri(buf->bufname()),
      position: {
        line: line - 1,
        character: col - 1,
      },
    }

    goto_declaration.RequestGotoDeclaration(ch, doc)
  enddef

  RequestForEachClient(OnRequest)
enddef

export def GotoDefinition(): void
  RequestForEachClient(goto_definition.Request)
enddef

# Buffer/Document sync
# ---

export def DocumentWillSave(id: string, buf: number): void
  if buf->getbufvar('&modified')
    document.NotifyWillSave(GetChannel(id), { uri: fs.ProjectFileToUri(buf->bufname()) })
  endif
enddef

export def DocumentDidSave(id: string, buf: number): void
  if buf->getbufvar('&modified')
    document.NotifyDidSave(GetChannel(id), { uri: fs.ProjectFileToUri(buf->bufname()) })
  endif
enddef

export def DocumentDidChange(id: string, buf: number): void
  if buf->getbufvar('&modified')
    # TODO: Figure out a way to be able to create diffs instead of
    #       sending the entire buffer.
    #
    #       Possible solutions: 
    #         + Implement Myers's O(ND) algorithm (caveat: need time to learn it)
    #         + Use listener_add() to provided changes (caveat: only works on insert mode, might need to debounce)
    const contentChanges = [{ text: fs.GetBufferContents(buf) }]

    document.NotifyDidChange(GetChannel(id), {
      uri: fs.ProjectFileToUri(buf->bufname()),
      version: buf->getbufvar('changedtick'),
      changes: contentChanges,
    })
  endif
enddef

export def DocumentDidOpen(id: string): void
  const buf = bufnr('%')
  const ft = buf->getbufvar('&filetype')
  const isFileType = GetConfig(id).filetypes->index(ft) != -1

  if !isFileType
    return
  endif

  document.NotifyDidOpen(GetChannel(id), {
    uri: fs.ProjectFileToUri(buf->bufname()),
    filetype: ft,
    version: buf->getbufvar('changedtick'),
    contents: fs.GetBufferContents(buf),
  })

  # Track this document lifecycle, include any other refs
  TrackDocument(id, { bufnr: buf })

  # Subscribe to buffer event until closed
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
    if !textDocumentSync->empty() && textDocumentSync->get('willSave', false)
      documentEvents->add({
        group: GetEventGroup(id),
        event: willSaveBufEvents,
        bufnr: buf,
        cmd: printf('call lspclient#DocumentWillSave("%s", %d)', id, buf)
      })
    endif

    if !textDocumentSync->empty() && textDocumentSync->get('save', false)
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

export def DocumentDidClose(id: string, buf: number): void
  RemoveDocument(id, buf)

  # Unsubscribe from changes and events
  autocmd_delete([
    {
      group: GetEventGroup(id),
      event: changeBufEvents,
      bufnr: buf,
    },
    {
      group: GetEventGroup(id),
      event: closeBufEvents,
      bufnr: buf,
    },
  ])
  
  document.NotifyDidClose(GetChannel(id), { uri: fs.ProjectFileToUri(buf->bufname()) })
enddef

# LSP Server functions
# ---

export def LspStartServer(id: string): void
  if IsChannelConnected(GetChannel(id))
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
    logger.LogInfo('SERVER CAPABILITIES: ' .. response->string())

    client.Initialized(ch)

    # Open the current document
    DocumentDidOpen(id)

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
    logger.LogInfo('STDOUT : ' .. data->string())
    router.HandleServerRequest(ch, data, GetConfig(id))
  enddef

  def OnStderr(ch: channel, data: any): void
    logger.PrintError('STDERR : ' .. data->string())
    logger.LogError('STDERR : ' .. data->string())
  enddef

  def OnExit(ch: channel): void
    logger.PrintInfo('Job Exiting')
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

  logger.PrintInfo('Starting LSP Server: ' .. lspClientConfig.name)

  const job = job_start(lspClientConfig.cmd, jobOpts)
  const channel = job_getchannel(job)

  SetJob(id, job)
  SetChannel(id, channel)

  # Start the initialization process
  logger.LogInfo('<======= LSP CLIENT LOG =======>')
  client.Initialize(GetChannel(id), {
    lspClientConfig: lspClientConfig,
    callback: OnInitialize,
  })
enddef

export def LspStopServer(id: string): void
  if !IsChannelConnected(GetChannel(id))
    return
  endif

  logger.LogInfo('<======= LSP CLIENT SHUTDOWN PHASE =======>')
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
  logger.PrintInfo('Registered servers: ' .. lspClients->keys()->join(','))
enddef
