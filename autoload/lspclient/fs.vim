vim9script

# Handle:
# Converstions between OS Filesystem and LSP URI format
# Buffer/File contents
# Directory resolution

export def DecodeUri(encodedUri: string): string
  def HexToChar(matched: list<string>): string
    const hexCode = '0x' .. matched[1]
    return hexCode->str2nr(16)->nr2char()
  enddef

  return encodedUri->substitute('%\(\x\x\)', HexToChar, 'g')
enddef

export def EncodeUri(decodedUri: string): string
  def CharToHex(matched: list<string>): string
    const hexStr = printf('%%%x', matched[1]->char2nr())
    return hexStr
  enddef

  return decodedUri->substitute('\([^A-Za-z0-9-._~:/]\)', CharToHex, 'g')
enddef

export def FileToUri(filepath: string): string
  const uri = printf('file://%s', filepath)
  return EncodeUri(uri)
enddef

export def UriToFile(uri: string): string
  const decodedUri = DecodeUri(uri)
  return decodedUri[7 :]
enddef

# Fullpath of buffer file to uri
export def BufferToUri(buf: number): string
  const filepath = buf->bufname()->fnamemodify(':p')
  return FileToUri(filepath)
enddef

export def UriToBuffer(uri: string): number
  return UriToFile(uri)->bufnr()
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

# Get the project full path as URI
export def GetProjectRootUri(): string
  return FileToUri(GetProjectRoot())
enddef

# Convert file residing in the project/workspace folder to a full path URI
export def ProjectFileToUri(relativeFilepath: string): string
  return FileToUri(GetProjectRoot(relativeFilepath))
enddef

export def GetFileContents(filepath: string): string
  return filepath->readfile()->join("\n")
enddef

export def GetBufferContents(buf: number): string
  return buf->getbufline(1, '$')->join("\n")
enddef

export def HasRootMarker(markers: list<string>): bool
  const cwd = getcwd()
  const markerPaths = markers->mapnew((_idx, marker) => printf('%s/%s', cwd, marker))

  for path in markerPaths
    if path->filereadable()
      return true
    endif
  endfor

  return false
enddef
