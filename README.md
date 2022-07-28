# vim-lspclient (WIP)

A highly experimental LSP client for vim. Written in vim9script.

## Motivation

I just wanted to try out a new language, at the same time, wanted to challenge myself on building something different/
unique besides just building web applications.

## What works

Ref: [LSP protocol spec](https://microsoft.github.io/language-server-protocol/specifications/specification-current)

+ Server Initialization (`initialize`, `initialized`)
+ Document updates:
    + `textDocument/didOpen`
    + `textDocument/didChange`
    + `textDocument/didClose`
    + `textDocument/willSave`
    + `textDocument/didSave`
+  Workspace features: 
    + `workspace/configuration`
    + `workspace/didChangeConfiguration`
+ Server Shutdown (`shutdown`, `exit`)

## Installation

For vim-plug and similar plugin managers:

```vim
Plug 'creativenull/vim-lspclient'
```

Without a plugin manager:

```
git clone https://github.com/creativenull/vim-lspclient.git ~/.vim/pack/creativenull/start/vim-lspclient
```

## Setup

Example for `tsserver`:

```vim
call lspclient#MakeLspClient({
  \ 'name': 'tsserver',
  \ 'cmd': ['typescript-language-server', '--stdio'],
  \ 'filetypes': ['typescript', 'typescriptreact', 'javascript', 'javascriptreact'],
  \ 'initOptions': {
    \ 'hostInfo': 'Vim 9',
  \ },
\ })
```
