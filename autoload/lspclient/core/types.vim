vim9script

export const MessageType = {
  1: 'Error',
  2: 'Warning',
  3: 'Info',
  4: 'Generic',
}

export const DiagnosticTag = {
  Unnecessary: 1,
  Deprecated: 2,
  1: 'Unnecessary',
  2: 'Deprecated',
}

export const DiagnosticSeverity = {
  1: 'E',
  2: 'W',
  3: 'I',
  4: 'H',
}

export const DocumentHighlightKind = {
  1: 'Text',
  2: 'Read',
  3: 'Write',
  Text: 1,
  Read: 2,
  Write: 3,
}

export const PositionEncodingKind = {
  UTF8: 'utf-8',
  UTF16: 'utf-16',
  UTF32: 'utf-32',
}

export const LanguageIds = [
  'abap',
  'bat',
  'bibtex',
  'clojure',
  'coffeescript',
  'c',
  'cpp',
  'csharp',
  'css',
  'diff',
  'dart',
  'dockerfile',
  'elixir',
  'erlang',
  'fsharp',
  'git-rebase',
  'go',
  'groovy',
  'handlebars',
  'html',
  'ini',
  'java',
  'javascript',
  'javascriptreact',
  'json',
  'latex',
  'less',
  'lua',
  'makefile',
  'markdown',
  'objective-c',
  'objective-cpp',
  'perl',
  'perl6',
  'php',
  'powershell',
  'jade',
  'python',
  'r',
  'razor',
  'ruby',
  'rust',
  'scss',
  'scala',
  'shaderlab',
  'shellscript',
  'sql',
  'swift',
  'typescript',
  'typescriptreact',
  'tex',
  'vb',
  'xml',
  'xsl',
  'yaml',
]
