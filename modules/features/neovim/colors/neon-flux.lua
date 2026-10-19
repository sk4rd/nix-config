-- Base tokens are generated from themes/neon-flux/palette.json by Home Manager.
local p = require('neon-flux-palette')

vim.opt.background = 'dark'
vim.cmd('highlight clear')
if vim.fn.exists('syntax_on') == 1 then
  vim.cmd('syntax reset')
end
vim.g.colors_name = 'neon-flux'

local function hl(name, value)
  vim.api.nvim_set_hl(0, name, value)
end
local function link(name, target)
  hl(name, { link = target })
end

local groups = {
  Normal = { fg = p.text, bg = p.canvas },
  NormalNC = { fg = p.text, bg = p.canvas },
  NormalFloat = { fg = p.text, bg = p.raised },
  FloatBorder = { fg = p.structure, bg = p.raised },
  FloatTitle = { fg = p.accent, bg = p.raised, bold = true },
  FloatFooter = { fg = p.muted, bg = p.raised },
  ColorColumn = { bg = p.surface },
  Cursor = { fg = p.canvas, bg = p.accent },
  CursorLine = { bg = p.currentLine },
  CursorColumn = { bg = p.currentLine },
  CursorLineNr = { fg = p.accent, bg = p.currentLine, bold = true },
  LineNr = { fg = p.lineNumber, bg = p.canvas },
  SignColumn = { fg = p.muted, bg = p.canvas },
  FoldColumn = { fg = p.muted, bg = p.canvas },
  Folded = { fg = p.muted, bg = p.surface },
  WinSeparator = { fg = p.border },
  EndOfBuffer = { fg = p.canvas },
  NonText = { fg = p.muted },
  Whitespace = { fg = p.lineNumber },
  SpecialKey = { fg = p.hot },
  Conceal = { fg = p.muted },
  Visual = { fg = p.text, bg = p.selection },
  VisualNOS = { bg = p.selection },
  Search = { fg = p.accentBright, bg = p.selection },
  IncSearch = { fg = p.canvas, bg = p.accent, bold = true },
  CurSearch = { fg = p.canvas, bg = p.accent, bold = true },
  Substitute = { fg = p.canvas, bg = p.error },
  MatchParen = { fg = p.accent, bg = p.selection, bold = true },
  StatusLine = { fg = p.text, bg = p.surface },
  StatusLineNC = { fg = p.muted, bg = p.surface },
  WinBar = { fg = p.text, bg = p.surface },
  WinBarNC = { fg = p.muted, bg = p.surface },
  TabLine = { fg = p.muted, bg = p.surface },
  TabLineFill = { bg = p.surface },
  TabLineSel = { fg = p.accent, bg = p.raised, bold = true },
  Pmenu = { fg = p.text, bg = p.raised },
  PmenuSel = { fg = p.text, bg = p.selection },
  PmenuSbar = { bg = p.surface },
  PmenuThumb = { bg = p.border },
  PmenuMatch = { fg = p.accent, bold = true },
  PmenuMatchSel = { fg = p.accent, bg = p.selection, bold = true },
  WildMenu = { fg = p.accent, bg = p.selection, bold = true },
  MsgArea = { fg = p.text, bg = p.canvas },
  MsgSeparator = { fg = p.border, bg = p.surface },
  MoreMsg = { fg = p.accent },
  ModeMsg = { fg = p.accent, bold = true },
  Question = { fg = p.accent, bold = true },
  Title = { fg = p.accent, bold = true },
  Directory = { fg = p.info },
  ErrorMsg = { fg = p.error, bold = true },
  WarningMsg = { fg = p.warning },
  SpellBad = { sp = p.error, undercurl = true },
  SpellCap = { sp = p.warning, undercurl = true },
  SpellLocal = { sp = p.info, undercurl = true },
  SpellRare = { sp = p.purple, undercurl = true },
  Comment = { fg = p.comment, italic = true },
  Constant = { fg = p.hot },
  String = { fg = p.warning },
  Character = { fg = p.warning },
  Number = { fg = p.hot },
  Boolean = { fg = p.hot },
  Float = { fg = p.hot },
  Identifier = { fg = p.text },
  Function = { fg = p.accent },
  Statement = { fg = p.purple },
  Operator = { fg = p.accentBright },
  PreProc = { fg = p.hot },
  Type = { fg = p.info },
  Special = { fg = p.muted },
  SpecialChar = { fg = p.hot },
  Delimiter = { fg = p.muted },
  Underlined = { fg = p.info, underline = true },
  Ignore = { fg = p.muted },
  Error = { fg = p.error, bold = true },
  Todo = { fg = p.warning, bold = true },
  Added = { fg = p.success },
  Changed = { fg = p.warning },
  Removed = { fg = p.error },
  DiffAdd = { fg = p.success, bg = p.surface },
  DiffChange = { fg = p.warning, bg = p.surface },
  DiffDelete = { fg = p.error, bg = p.surface },
  DiffText = { fg = p.warning, bg = p.selection, bold = true },
  diffAdded = { fg = p.success },
  diffRemoved = { fg = p.error },
  diffChanged = { fg = p.warning },
  diffFile = { fg = p.accent, bg = p.raised, bold = true },
  diffNewFile = { fg = p.success },
  diffOldFile = { fg = p.error },
  diffIndexLine = { fg = p.info, bg = p.surface },
  diffLine = { fg = p.purple, bg = p.surface },
  GitSignsAdd = { fg = p.success },
  GitSignsChange = { fg = p.warning },
  GitSignsDelete = { fg = p.error },
  GitSignsChangeDelete = { fg = p.warning },
  GitSignsUntracked = { fg = p.info },
  GitSignsAddInline = { fg = p.success, bg = p.selection },
  GitSignsChangeInline = { fg = p.warning, bg = p.selection },
  GitSignsDeleteInline = { fg = p.error, bg = p.selection },
  GitSignsCurrentLineBlame = { fg = p.comment, italic = true },
  TelescopeNormal = { fg = p.text, bg = p.raised },
  TelescopeBorder = { fg = p.structure, bg = p.raised },
  TelescopeTitle = { fg = p.accent, bg = p.raised, bold = true },
  TelescopePromptPrefix = { fg = p.accent, bg = p.raised },
  TelescopeSelection = { fg = p.text, bg = p.selection },
  TelescopeSelectionCaret = { fg = p.accent, bg = p.selection },
  TelescopeMultiSelection = { fg = p.hot, bg = p.selection },
  TelescopeMatching = { fg = p.accent, bold = true },
  CmpItemAbbr = { fg = p.text },
  CmpItemAbbrDeprecated = { fg = p.muted, strikethrough = true },
  CmpItemAbbrMatch = { fg = p.accent, bold = true },
  CmpItemAbbrMatchFuzzy = { fg = p.accent, bold = true },
  CmpItemMenu = { fg = p.muted },
  CmpItemKind = { fg = p.muted },
  LspReferenceText = { bg = p.selection },
  LspReferenceRead = { bg = p.selection },
  LspReferenceWrite = { bg = p.selection, underline = true },
  LspInlayHint = { fg = p.muted, bg = p.surface },
  LspCodeLens = { fg = p.comment, italic = true },
  LspCodeLensSeparator = { fg = p.border },
  LspSignatureActiveParameter = { fg = p.accent, bg = p.selection, bold = true },
  -- Org headings use restrained foreground accents, never saturated surfaces.
  org_headline_level_1 = { fg = p.accent, bold = true },
  org_headline_level_2 = { fg = p.structure, bold = true },
  org_headline_level_3 = { fg = p.info, bold = true },
  org_headline_level_4 = { fg = p.purple, bold = true },
  org_headline_level_5 = { fg = p.accentBright, bold = true },
  org_headline_level_6 = { fg = p.hot, bold = true },
  org_headline_level_7 = { fg = p.info, bold = true },
  org_headline_level_8 = { fg = p.muted, bold = true },
  org_todo = { fg = p.warning, bold = true },
  org_done = { fg = p.success, bold = true },
  org_priority = { fg = p.hot },
  org_tag = { fg = p.muted },
  org_timestamp = { fg = p.info },
  org_timestamp_inactive = { fg = p.muted },
  org_link = { fg = p.info, underline = true },
  org_checkbox = { fg = p.accentBright },
  org_checkbox_checked = { fg = p.success },
  org_checkbox_halfchecked = { fg = p.warning },
  org_agenda_deadline = { fg = p.error },
  org_agenda_scheduled = { fg = p.success },
  org_agenda_scheduled_past = { fg = p.warning },
  org_agenda_today = { fg = p.accent, bold = true },
}
for name, value in pairs(groups) do
  hl(name, value)
end

for _, name in ipairs({ 'Conditional', 'Repeat', 'Label', 'Keyword', 'Exception' }) do
  link(name, name == 'Label' and 'Constant' or 'Statement')
end
for _, name in ipairs({ 'Include', 'Define', 'Macro', 'PreCondit' }) do
  link(name, 'PreProc')
end
link('StorageClass', 'Statement')
link('Typedef', 'Type')
link('Structure', 'Type')
link('SpecialComment', 'Comment')
link('Debug', 'Special')
link('CursorIM', 'Cursor')
link('lCursor', 'Cursor')
link('TermCursor', 'Cursor')
link('CursorLineSign', 'SignColumn')
link('CursorLineFold', 'FoldColumn')
link('LineNrAbove', 'LineNr')
link('LineNrBelow', 'LineNr')
link('QuickFixLine', 'Visual')
link('SnippetTabstop', 'Visual')
link('SnippetTabstopActive', 'LspSignatureActiveParameter')

for severity, color in pairs({ Error = p.error, Warn = p.warning, Info = p.info, Hint = p.info, Ok = p.success }) do
  hl('Diagnostic' .. severity, { fg = color })
  hl('DiagnosticSign' .. severity, { fg = color, bg = p.canvas })
  hl('DiagnosticFloating' .. severity, { fg = color, bg = p.raised })
  hl('DiagnosticVirtualText' .. severity, { fg = color })
  hl('DiagnosticVirtualLines' .. severity, { fg = color })
  hl('DiagnosticUnderline' .. severity, { sp = color, undercurl = true })
end
hl('DiagnosticDeprecated', { fg = p.muted, strikethrough = true })
hl('DiagnosticUnnecessary', { fg = p.muted })

local syntax = {
  ['@variable'] = 'Identifier',
  ['@variable.builtin'] = 'Identifier',
  ['@variable.parameter'] = 'Identifier',
  ['@variable.member'] = 'Operator',
  ['@constant'] = 'Constant',
  ['@constant.builtin'] = 'Constant',
  ['@constant.macro'] = 'Constant',
  ['@module'] = 'Type',
  ['@module.builtin'] = 'Type',
  ['@label'] = 'Constant',
  ['@string'] = 'String',
  ['@string.documentation'] = 'Comment',
  ['@string.regexp'] = 'Error',
  ['@string.escape'] = 'SpecialChar',
  ['@string.special'] = 'String',
  ['@string.special.url'] = 'Underlined',
  ['@character'] = 'Character',
  ['@character.special'] = 'SpecialChar',
  ['@boolean'] = 'Boolean',
  ['@number'] = 'Number',
  ['@number.float'] = 'Float',
  ['@type'] = 'Type',
  ['@type.builtin'] = 'Type',
  ['@type.definition'] = 'Type',
  ['@type.parameter'] = 'Operator',
  ['@attribute'] = 'String',
  ['@attribute.builtin'] = 'String',
  ['@property'] = 'Operator',
  ['@function'] = 'Function',
  ['@function.builtin'] = 'Function',
  ['@function.call'] = 'Function',
  ['@function.macro'] = 'Constant',
  ['@function.method'] = 'Function',
  ['@function.method.call'] = 'Function',
  ['@constructor'] = 'Function',
  ['@operator'] = 'Operator',
  ['@keyword'] = 'Statement',
  ['@keyword.modifier'] = 'Statement',
  ['@keyword.operator'] = 'Operator',
  ['@punctuation'] = 'Delimiter',
  ['@punctuation.delimiter'] = 'Delimiter',
  ['@punctuation.bracket'] = 'Delimiter',
  ['@punctuation.special'] = 'Delimiter',
  ['@comment'] = 'Comment',
  ['@comment.documentation'] = 'Comment',
  ['@comment.error'] = 'DiagnosticError',
  ['@comment.warning'] = 'DiagnosticWarn',
  ['@comment.todo'] = 'Todo',
  ['@comment.note'] = 'DiagnosticInfo',
  ['@markup.heading'] = 'Title',
  ['@markup.link'] = 'Underlined',
  ['@markup.link.label'] = 'Underlined',
  ['@markup.link.url'] = 'Underlined',
  ['@markup.raw'] = 'String',
  ['@markup.list'] = 'Operator',
  ['@markup.list.checked'] = 'DiagnosticOk',
  ['@markup.list.unchecked'] = 'Todo',
  ['@diff.plus'] = 'Added',
  ['@diff.minus'] = 'Removed',
  ['@diff.delta'] = 'Changed',
  ['@tag'] = 'Type',
  ['@tag.attribute'] = 'Operator',
  ['@tag.delimiter'] = 'Delimiter',
  ['@none'] = 'Special',
}
for name, target in pairs(syntax) do
  link(name, target)
end
-- Do not let semantic defaults replace the palette's syntax roles.
local semantic = {
  namespace = 'Type', type = 'Type', class = 'Type', enum = 'Type',
  interface = 'Type', struct = 'Type', typeParameter = 'Operator',
  parameter = 'Identifier', variable = 'Identifier', property = 'Operator',
  enumMember = 'Constant', event = 'Identifier', ['function'] = 'Function',
  method = 'Function', macro = 'Constant', keyword = 'Statement',
  modifier = 'Statement', comment = 'Comment', string = 'String',
  number = 'Number', regexp = 'Error', operator = 'Operator',
  decorator = 'String', label = 'Constant',
}
for name, target in pairs(semantic) do
  link('@lsp.type.' .. name, target)
end
-- Readonly/default-library modifiers do not turn variables into constants.
for _, modifier in ipairs({ 'declaration', 'definition', 'readonly', 'static', 'abstract', 'async', 'modification', 'documentation', 'defaultLibrary' }) do
  hl('@lsp.mod.' .. modifier, {})
end
hl('@lsp.mod.deprecated', { strikethrough = true })
hl('@markup.strong', { bold = true })
hl('@markup.italic', { italic = true })
hl('@markup.strikethrough', { strikethrough = true })
hl('@markup.underline', { underline = true })

for kind, target in pairs({
  Text = 'Identifier', Method = 'Function', Function = 'Function', Constructor = 'Function',
  Field = 'Operator', Variable = 'Identifier', Class = 'Type', Interface = 'Type',
  Module = 'Type', Property = 'Operator', Unit = 'Constant', Value = 'Constant',
  Enum = 'Type', Keyword = 'Statement', Snippet = 'String', Color = 'Special',
  File = 'Directory', Reference = 'Underlined', Folder = 'Directory', EnumMember = 'Constant',
  Constant = 'Constant', Struct = 'Type', Event = 'Identifier', Operator = 'Operator', TypeParameter = 'Operator',
}) do
  link('CmpItemKind' .. kind, target)
end
for _, part in ipairs({ 'Prompt', 'Results', 'Preview' }) do
  link('Telescope' .. part .. 'Normal', 'TelescopeNormal')
  link('Telescope' .. part .. 'Border', 'TelescopeBorder')
  link('Telescope' .. part .. 'Title', 'TelescopeTitle')
end
for level = 1, 8 do
  link('@org.headline.level' .. level, 'org_headline_level_' .. level)
  link('@markup.heading.' .. level .. '.org', 'org_headline_level_' .. level)
end
for capture, target in pairs({
  todo = 'org_todo', done = 'org_done', priority = 'org_priority', tag = 'org_tag',
  timestamp = 'org_timestamp', ['timestamp.active'] = 'org_timestamp',
  ['timestamp.inactive'] = 'org_timestamp_inactive',
}) do
  link('@org.' .. capture, target)
end

local ansi = { p.surface, p.error, p.success, p.warning, p.info, p.purple, p.accent, p.text }
-- The bright-only colors are not base tokens: keep the desktop ansiBright row.
local ansi_bright = { '#53607A', '#FF6B81', '#6FFFD4', '#FFF28A', '#74C0FF', '#D19CFF', p.accentBright, '#FFFFFF' }
for index, color in ipairs(ansi) do
  vim.g['terminal_color_' .. (index - 1)] = color
end
for index, color in ipairs(ansi_bright) do
  vim.g['terminal_color_' .. (index + 7)] = color
end
