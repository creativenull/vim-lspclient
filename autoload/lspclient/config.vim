vim9script

# interface LspClientConfig {
#   name: string;
#   cmd: list<string>;
#   filetypes: list<string>;
#   markers: list<string>;
#   initOptions?: dict<any>;
#   capabilities?: dict<any>;
#   settings?: dict<any>;
# }

export def MergeLspClientConfig(partialLspClientConfig: dict<any>): dict<any>
  const defaults = {
    capabilities: null_dict,
    initOptions: null_dict,
    settings: null_dict,
  }

  return defaults->extendnew(partialLspClientConfig)
enddef

export def ValidateLspClientConfig(lspClientConfig: dict<any>): string
  var errlist = []

  if !lspClientConfig->has_key('name')
    errlist->add('name')
  endif

  if !lspClientConfig->has_key('cmd')
    errlist->add('cmd')
  endif

  if !lspClientConfig->has_key('filetypes')
    errlist->add('filetypes')
  endif

  if !lspClientConfig->has_key('markers')
    errlist->add('markers')
  endif

  if !errlist->empty()
    return 'Missing arguments: ' .. errlist->join(',')
  endif

  # Also check if provided `cmd` is executable
  if !lspClientConfig.cmd[0]->executable()
    return '`cmd` is not executable. Check if ' .. lspClientConfig.cmd[0] .. ' if installed in the system.'
  endif

  return ''
enddef
