vim9script

# Handle:
# Converstions between OS Filesystem and LSP URI format
# Buffer/File contents
# Directory resolution

export def FileToUri(filepath: string): string
  return printf('file://%s', filepath)
enddef

export def UriToFile(uri: string): string
  return uri[7 :]
enddef

export def GetProjectRoot(extendPath: string = ''): string
  if !extendPath->empty()
    if extendPath[0] == '/'
      return printf('%s%s', getcwd(), extendPath)
    endif

    return printf('%s/%s', getcwd(), extendPath)
  endif

  return getcwd()
enddef

export def GetProjectRootUri(): string
  return FileToUri(GetProjectRoot())
enddef

export def GetCurrentFileUri(): string
  return FileToUri(expand('%'))
enddef

export def GetFileContents(filepath: string): string
  return filepath->readfile()->join("\n")
enddef

export def GetBufferContents(buf: number): string
  return buf->getbufline(1, '$')->join("\n")
enddef
