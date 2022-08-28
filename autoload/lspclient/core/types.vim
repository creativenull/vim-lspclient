vim9script

export const MessageType = {
  1: 'Error',
  2: 'Warning',
  3: 'Info',
  4: 'Hint',
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

export const SymbolKind = {
  File: 1,
	Module: 2,
	Namespace: 3,
	Package: 4,
	Class: 5,
	Method: 6,
	Property: 7,
	Field: 8,
	Constructor: 9,
	Enum: 10,
	Interface: 11,
	Function: 12,
	Variable: 13,
	Constant: 14,
	String: 15,
	Number: 16,
	Boolean: 17,
	Array: 18,
	Object: 19,
	Key: 20,
	Null: 21,
	EnumMember: 22,
	Struct: 23,
	Event: 24,
	Operator: 25,
	TypeParameter: 26,
}

export const SymbolTag = { Deprecated: 1 }

export const FoldingRangeKind = {
  Comment: 'comment',
  Imports: 'imports',
  Region: 'region',
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
