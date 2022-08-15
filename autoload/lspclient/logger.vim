vim9script

# Logger to handle messages from the LSP server/client to the user. Logs to
# :messages and a log file.

const logFilepath = expand('~/.cache/vim/lspclient.log')
const messagesPrefix = '[LSPCLIENT]'
const Level = {
  Error: 'ERROR',
  Debug: 'DEBUG',
  Info: 'INFO',
}

# Get the current timestamp format for logfiles
def GetTime(): string
  return strftime('%Y-%m-%d %T')
enddef

# Ensure logfile is created to be written into
def EnsureLogFile(): void
  const dirpath = fnamemodify(logFilepath, ':h')

  if !filereadable(logFilepath)
    execute printf('!mkdir -p %s', dirpath)
    execute printf('!touch %s', logFilepath)
  endif
enddef

# Write infomation to the logfile
def WriteLogFile(msg: string): void
  writefile([msg], logFilepath, 'a')
enddef

# Generic format for messages to be logged as
export def Render(level: string, msg: string): string
  return printf('%s: %s', level, msg)
enddef

# Logs to be printed to :messages
export def Print(level: string, msg: string, isError = false): void
  if isError
    echoerr printf('%s %s', messagesPrefix, Render(level, msg))
  else
    echomsg printf('%s %s', messagesPrefix, Render(level, msg))
  endif
enddef

# Log to be writted to logfiles
export def Log(level: string, msg: string): void
  EnsureLogFile()
  WriteLogFile(printf('[%s] %s', GetTime(), Render(level, msg)))
enddef

# Debug Functions
# ---
export const Debug = (msg: string): string => Render(Level.Debug, msg)

export def PrintDebug(msg: string): void
  if !exists('g:lspclient_debug') || (exists('g:lspclient_debug') && !g:lspclient_debug)
    return
  endif

  Print(Level.Debug, msg)
enddef

export def LogDebug(msg: string): void
  if !exists('g:lspclient_debug') || (exists('g:lspclient_debug') && !g:lspclient_debug)
    return
  endif

  Log(Level.Debug, msg)
enddef

# Info Functions
# ---
export const Info = (msg: string): string => Render(Level.Info, msg)

export def PrintInfo(msg: string): void
  Print(Level.Info, msg)
enddef

export def LogInfo(msg: string): void
  Log(Level.Info, msg)
enddef

# Error Functions
# ---
export const Error = (msg: string): string => Render(Level.Error, msg)

export def PrintError(msg: string): void
  Print(Level.Error, msg, true)
enddef

export def LogError(msg: string): void
  Log(Level.Error, msg)
enddef

# Log Utils
# ---
export def OpenLogFilepath(): void
  execute printf('silent edit %s', logFilepath)
enddef

export def ClearLogContents(): void
  writefile([], logFilepath, 'w')
enddef
