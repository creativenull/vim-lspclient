# vim-lspclient (WIP)

A highly experimental LSP client for vim using the builtin [LSP channel mode](https://vimhelp.org/channel.txt.html#language-server-protocol).
Written in `vim9script`.

## Motivation

I just wanted to try out a new language, at the same time, wanted to challenge myself on building something different/
unique besides just building web applications.

## What works

Ref: [LSP Specification](https://microsoft.github.io/language-server-protocol/specifications/specification-current)

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
### Requirements

These can also be checked with `:LSPClientCheckHealth`

+ Vim [v8.2.4758](https://github.com/vim/vim/tree/v8.2.4758) and up is required.
+ `+channel`
+ `+job`
+ `+timers`

### Install via plugin manager

```vim
Plug 'creativenull/vim-lspclient'
```

### Install without plugin manager

```
git clone https://github.com/creativenull/vim-lspclient.git ~/.vim/pack/creativenull/start/vim-lspclient
```

## Setup

Example for `tsserver`:

```vim
call lspclient#Create({
  \ 'name': 'tsserver',
  \ 'cmd': ['typescript-language-server', '--stdio'],
  \ 'filetypes': ['typescript', 'typescriptreact', 'javascript', 'javascriptreact'],
  \ 'initOptions': {
    \ 'hostInfo': 'Vim 9',
  \ },
\ })
```
