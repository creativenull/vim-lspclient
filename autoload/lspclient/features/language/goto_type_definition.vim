vim9script

import './common/goto.vim'

const method = 'textDocument/typeDefinition'

export def Request(ch: channel, buf: number, context: dict<any>): void
  goto.Request(ch, method, buf, context)
enddef

export def Register(ch: channel, registrationOptions: any, lspClientConfig: dict<any>): void
  goto.Register(ch, method, registrationOptions, lspClientConfig)
enddef
