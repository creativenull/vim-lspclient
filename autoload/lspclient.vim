vim9script

import './lspclient/core/client.vim'
import './lspclient/core/document.vim'
import './lspclient/core/fs.vim'
import './lspclient/core/log.vim'
import './lspclient/router.vim'
import './lspclient/config.vim'

# Events
const openBufEvents = ['BufRead']
const closeBufEvents = ['BufDelete']
const willSaveBufEvents = ['BufWritePre']
const didSaveBufEvents = ['BufWrite']

var lspClients = {}

def HasStarted(ch: channel): bool
  return ch->ch_status() == 'open'
enddef

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

def TrackDocument(id: string, newValue: dict<any>): void
  lspClients[id].documents->add(newValue)
enddef

def RemoveDocument(id: string, buf: number): dict<any>
  const result = filter(copy(GetDocuments(id)), (i, val) => val.bufnr == buf)

  if !result->empty()
    return result[0]
  endif

  return null_dict
enddef

# Buffer/Document sync
# ---

export def DocumentWillSave(id: string, buf: number): void
  if buf->getbufvar('&modified')
    document.NotifyWillSave(GetChannel(id), { uri: fs.FileToUri(buf->bufname()) })
  endif
enddef

export def DocumentDidSave(id: string, buf: number): void
  if buf->getbufvar('&modified')
    document.NotifyDidSave(GetChannel(id), { uri: fs.FileToUri(buf->bufname()) })
  endif
enddef

export def DocumentDidChange(id: string, buf: number): void
  if buf->getbufvar('&modified')
    document.NotifyDidChange(GetChannel(id), {
      uri: fs.FileToUri(buf->bufname()),
      version: buf->getbufvar('changedtick'),
      contents: fs.GetBufferContents(buf),
    })
  endif
enddef

export def DocumentDidOpen(id: string): void
  const buf = bufnr('%')

  const ft = buf->getbufvar('&filetype')
  const isFileType = GetConfig(id).filetypes->index(ft) != -1
  if isFileType
    document.NotifyDidOpen(GetChannel(id), {
      uri: fs.FileToUri(buf->bufname()),
      filetype: ft,
      version: buf->getbufvar('changedtick'),
      contents: fs.GetBufferContents(buf),
    })

    # Subscribe to buffer changes
    def OnChange(bufnr: number, start: any, end: any, added: any, changes: any)
      DocumentDidChange(id, bufnr)
    enddef

    const ref = listener_add(OnChange, buf)

    # Track this document lifecycle, include any other refs
    TrackDocument(id, { bufnr: buf, listenerRef: ref })

    # Register for cleanup
    autocmd_add([
      {
        group: GetEventGroup(id),
        event: closeBufEvents,
        bufnr: buf,
        cmd: printf('call lspclient#DocumentDidClose("%s", %d)', id, buf)
      },
      {
        group: GetEventGroup(id),
        event: willSaveBufEvents,
        bufnr: buf,
        cmd: printf('call lspclient#DocumentWillSave("%s", %d)', id, buf)
      },
      {
        group: GetEventGroup(id),
        event: didSaveBufEvents,
        bufnr: buf,
        cmd: printf('call lspclient#DocumentDidSave("%s", %d)', id, buf)
      },
    ])
  endif
enddef

export def DocumentDidClose(id: string, buf: number): void
  const doc = RemoveDocument(id, buf)

  # Unsubscribe from changes and events
  listener_remove(doc.listenerRef)
  autocmd_delete([
    {
      group: lspClients[id].group,
      event: closeBufEvents,
      bufnr: buf,
    },
  ])
  
  document.NotifyDidClose(GetChannel(id), { uri: fs.FileToUri(buf->bufname()) })
enddef

# LSP Server functions
# ---

export def LspStartServer(id: string): void
  if HasStarted(GetChannel(id))
    return
  endif

  # Notify the server that the client has initialized once
  # the response provides no errors
  def OnInitialize(ch: channel, response: dict<any>): void
    var errmsg = ''

    if response->empty()
      errmsg = 'Empty Response'
      log.LogError(errmsg)

      return
    endif

    if response->has_key('error')
      errmsg = response.error->string()
      log.LogError(errmsg)

      return
    endif

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

  def OnStdout(ch: channel, request: dict<any>): void
    log.LogInfo('STDOUT : ' .. request->string())
    router.HandleServerRequest(ch, request, GetConfig(id))
  enddef

  def OnStderr(ch: channel, data: any): void
    log.LogError('STDERR : ' .. data->string())
  enddef

  def OnExit(ch: channel, data: any): void
    log.LogInfo('Channel Exiting')
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

  log.PrintInfo('Starting LSP Server: ' .. lspClientConfig.name)

  const job = job_start(lspClientConfig.cmd, jobOpts)
  const channel = job_getchannel(job)

  SetJob(id, job)
  SetChannel(id, channel)

  # Start the initialization process
  log.LogInfo('<======= LSP CLIENT LOG =======>')
  client.Initialize(GetChannel(id), {
    lspClientConfig: lspClientConfig,
    callback: OnInitialize,
  })
enddef

export def LspStopServer(id: string): void
  if !HasStarted(GetChannel(id))
    return
  endif

  log.LogInfo('<======= LSP CLIENT SHUTDOWN PHASE =======>')
  client.Shutdown(GetChannel(id))
enddef

export def MakeLspClient(partialLspClientConfig: dict<any>): void
  # Merge and validate the client config and fail the setup
  # if invalidated
  const lspClientConfig = config.MergeLspClientConfig(partialLspClientConfig)

  const errmsg = config.ValidateLspClientConfig(lspClientConfig)
  if !errmsg->empty()
    log.PrintError(errmsg)
    log.LogError(errmsg)

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
