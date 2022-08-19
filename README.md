# vim-lspclient (WIP)

A highly experimental LSP client for vim using the builtin [LSP channel mode](https://vimhelp.org/channel.txt.html#language-server-protocol).
Written in `vim9script`.

## Motivation

I just wanted to try out a new language, at the same time, wanted to challenge myself on building something different/
unique besides just building web applications.

## What works

Ref: [LSP Specification v3.17](https://microsoft.github.io/language-server-protocol/specifications/specification-current)

+ Server Initialization (`initialize` and `initialized`)
+ Server Shutdown (`shutdown` and `exit`)
+ Dynamic Registration Capability
    + `workspace/didChangeConfiguration`
+ Document updates
    + `textDocument/didOpen`
    + `textDocument/didChange`
    + `textDocument/didClose`
    + `textDocument/willSave`
    + `textDocument/didSave`
+ Language features
    + `textDocument/publishDiagnostics`
    + `textDocument/declaration`
    + `textDocument/definition`
    + `textDocument/typeDefinition`
    + `textDocument/implementation`
    + `textDocument/hover`
+  Workspace features 
    + `workspace/configuration`
    + `workspace/didChangeConfiguration`
    + `workspace/workspaceFolders` (WIP)
+ Window features
    + `window/showMessageRequest` (WIP)
    + `window/showMessage`
    + `window/logMessage`
    + `window/workDoneProgress/create` (WIP)
    + `window/workDoneProgress/cancel` (WIP)

## Installation
### Requirements

The following version and features are required, these can also be checked with `:LSPClientCheckHealth`:

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

### Keymaps

```vim
" Example keymaps
nmap <Leader>lgd <Plug>(lspclient_definition)
nmap <Leader>lge <Plug>(lspclient_declaration)
nmap <Leader>lgi <Plug>(lspclient_implementation)
nmap <Leader>lgt <Plug>(lspclient_type_definition)
nmap <Leader>le <Plug>(lspclient_diagnostics)
nmap <Leader>lo <Plug>(lspclient_diagnostic_next)
nmap <Leader>li <Plug>(lspclient_diagnostic_prev)
nmap <Leader>lw <Plug>(lspclient_diagnostic_hover)
nmap <Leader>lw <Plug>(lspclient_diagnostic_hover)
nmap <Leader>lh <Plug>(lspclient_hover)
```

### Enable Debug Logs

Check logs with `:LSPClientLog` or `vim +LSPClientLog` (in terminal)

```vim
let g:lspclient_debug = 1
```

### LSP Servers Setup Examples

#### tsserver (js/ts)

Must have `typescript-language-server` installed globally with `npm i -g typescript-language-server`.

```vim
let s:tsserver = {}
let s:tsserver.name = 'tsserver'
let s:tsserver.cmd = ['typescript-language-server', '--stdio']
let s:tsserver.filetypes = ['typescript', 'typescriptreact', 'javascript', 'javascriptreact']
let s:tsserver.initOptions = { 'hostInfo': 'Vim 9' }
let s:tsserver.markers = ['tsconfig.json', 'jsconfig.json', 'package.json']

call lspclient#Create(s:tsserver)
```

#### volar (vue >= 3)

Must have `vue-language-server` installed globally with `npm i -g @volar/vue-language-server`

```vim
let s:volar = {}
let s:volar.name = 'volar'
let s:volar.cmd = ['vue-language-server', '--stdio']
let s:volar.filetypes = ['vue']
let s:volar.markers = ['package.json', 'vite.config.js', 'vite.config.ts']

" https://github.com/johnsoncodehk/volar/blob/d27d989355adc2aa3f9c6260226bd3167e3fac97/packages/shared/src/types.ts
let s:volar.initOptions = {
\   'typescript': {
\     'serverPath': lspclient#fs#GetProjectRoot('node_modules/typescript/lib/tsserverlibrary.js'),
\   },
\   'documentFeatures': {
\     'allowedLanguageIds': ['html', 'css', 'vue', 'typescript'],
\     'selectionRange': v:true,
\     'foldingRange': v:true,
\     'linkedEditingRange': v:true,
\     'documentSymbol': v:true,
\     'documentColor': v:true,
\     'documentFormatting': v:true,
\   },
\   'languageFeatures': {
\     'references': v:true,
\     'implementation': v:true,
\     'definition': v:true,
\     'typeDefinition': v:true,
\     'callHierarchy': v:true,
\     'hover': v:true,
\     'rename': v:true,
\     'renameFileRefactoring': v:true,
\     'signatrueHelp': v:true,
\     'completion': {
\     	'defaultTagNameCase': 'both',
\     	'defaultAttrNameCase': 'kebabCase',
\     	'getDocumentNameCasesRequest': v:true,
\     	'getDocumentSelectionRequest': v:true,
\     },
\     'documentHighlight': v:true,
\     'documentLink': v:true,
\     'workspaceSymbol': v:true,
\     'codeLens': v:true,
\     'semanticTokens': v:true,
\     'codeAction': v:true,
\     'inlayHints': v:false,
\     'diagnostics': v:true,
\     'schemaRequestService': v:true,
\   },
\ }

call lspclient#Create(s:volar)
```

#### deno (js/ts)

Must have `deno` installed globally.

```vim
let s:denols = {}
let s:denols.name = 'denols'
let s:denols.cmd = ['deno', 'lsp']
let s:denols.filetypes = ['typescript', 'typescriptreact', 'javascript', 'javascriptreact']
let s:denols.settings = { 'enable': v:true, 'unstable': v:true }
let s:denols.markers = ['deno.json', 'deno.jsonc']

call lspclient#Create(s:denols)
```
