vim.g.mapleader = ' '
vim.g.maplocalleader = ','
vim.opt.termguicolors = true
vim.opt.background = 'dark'
vim.opt.guifont = 'JetBrainsMono NFM:h12'
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.signcolumn = 'yes'
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = -1 -- Tab follows the detected shiftwidth.
-- Filetype defaults for new Nix buffers; Sleuth detects existing file style.
vim.api.nvim_create_autocmd('FileType', { pattern = 'nix', callback = function()
  vim.opt_local.expandtab = true
  vim.opt_local.shiftwidth = 2
  vim.opt_local.tabstop = 2
end })
vim.opt.textwidth = 80
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.scrolloff = 5
vim.opt.updatetime = 250
vim.opt.timeoutlen = 500
vim.opt.undofile = true
vim.opt.clipboard = 'unnamedplus'
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
vim.cmd.colorscheme('neon-flux')

local map = function(key, action, desc)
  vim.keymap.set('n', key, action, { desc = desc, silent = true })
end
local telescope = require('telescope.builtin')
require('telescope').setup({ defaults = { sorting_strategy = 'ascending', layout_config = { prompt_position = 'top' } } })
map('<leader>ff', telescope.find_files, 'Find files')
map('<leader>fr', telescope.oldfiles, 'Recent files')
map('<leader>bb', telescope.buffers, 'Buffers')
map('<leader>sp', telescope.live_grep, 'Search project')
map('<leader>sb', telescope.current_buffer_fuzzy_find, 'Search buffer')
map('<leader>ss', telescope.lsp_document_symbols, 'Document symbols')
map('<leader>sh', telescope.help_tags, 'Help')
map('<leader>pf', telescope.git_files, 'Project files (Git)')
map('<leader>pd', function() vim.cmd.lcd(vim.fs.root(0, { '.git', 'flake.nix' }) or vim.fn.getcwd()) end, 'Use project root')
-- yazi.nvim runs in chooser mode, so dispatch selected documents explicitly.
package.preload['neon-flux-file-opener'] = function()
  return function(path)
    local result = vim.system({ 'file', '--brief', '--mime-type', '--', path }, { text = true }):wait()
    if result.code ~= 0 then
      vim.notify('Cannot identify file: ' .. path, vim.log.levels.ERROR)
      return
    end
    local mime = vim.trim(result.stdout)
    local editable = mime:match('^text/') or mime == 'application/json'
      or mime == 'application/xml' or mime == 'application/javascript'
      or mime == 'application/x-empty' or mime == 'inode/x-empty'
    if editable then
      vim.cmd.edit(vim.fn.fnameescape(path))
    else
      local _, err = vim.ui.open(path)
      if err then vim.notify(tostring(err), vim.log.levels.ERROR) end
    end
  end
end
require('yazi').setup({
  open_for_directories = true,
  open_file_function = require('neon-flux-file-opener'),
  set_keymappings_function = function(buf)
    vim.keymap.set('t', '<Esc>', 'q', { buffer = buf, nowait = true, desc = 'Close Yazi' })
  end,
})
map('<leader>fd', '<cmd>Yazi<cr>', 'Directory browser (Yazi)')
require('neo-tree').setup({
  sources = { 'filesystem', 'buffers', 'git_status' },
  window = { position = 'right', width = 32 },
  filesystem = {
    bind_to_cwd = true,
    cwd_target = { sidebar = 'tab', current = 'window' },
    hijack_netrw_behavior = 'disabled', -- Yazi owns opening directories.
  },
})
map('<leader>fe', '<cmd>Neotree toggle filesystem right<cr>', 'Toggle sidebar explorer')
map('<leader>ww', '<cmd>write<cr>', 'Save')
map('<leader>qq', '<cmd>quit<cr>', 'Quit')

map('<leader>tv', '<cmd>vsplit | terminal<cr>', 'Terminal')
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Leave terminal mode' })
require('neogit').setup({
  kind = 'tab',
  fetch_after_checkout = false,
  integrations = { telescope = true, diffview = true },
})
map('<leader>gg', '<cmd>Neogit<cr>', 'Git status (Neogit)')
map('<leader>gd', '<cmd>DiffviewOpen<cr>', 'Review Git diff')
map('<leader>gh', '<cmd>DiffviewFileHistory %<cr>', 'Current file history')
require('gitsigns').setup({ on_attach = function(buf)
  local gs = require('gitsigns')
  for key, action in pairs({ [']h'] = gs.next_hunk, ['[h'] = gs.prev_hunk,
    ['<leader>gp'] = gs.preview_hunk, ['<leader>gs'] = gs.stage_hunk,
    ['<leader>gr'] = gs.reset_hunk, ['<leader>gb'] = gs.blame_line }) do
    vim.keymap.set('n', key, action, { buffer = buf, desc = 'Git ' .. key })
  end
end })
require('which-key').setup({ delay = 300 })
require('which-key').add({
  { '<leader>f', group = 'Files' }, { '<leader>b', group = 'Buffers' },
  { '<leader>s', group = 'Search' }, { '<leader>p', group = 'Project' },
  { '<leader>g', group = 'Git' }, { '<leader>c', group = 'Code' },
  { '<leader>n', group = 'Notes' }, { '<leader>t', group = 'Terminal' },
})
require('lualine').setup({ options = { theme = 'auto', globalstatus = true },
  sections = { lualine_c = { { 'filename', path = 1 }, 'lsp_status' } } })
require('direnv').setup({})
require('nvim-autopairs').setup({ map_cr = false })
local cmp = require('cmp')
cmp.setup({
  snippet = { expand = function(args) vim.snippet.expand(args.body) end },
  mapping = {
    ['<C-Space>'] = cmp.mapping.complete(), ['<C-y>'] = cmp.mapping.confirm({ select = false }),
    ['<Tab>'] = cmp.mapping.confirm({ select = false }),
    ['<C-n>'] = cmp.mapping.select_next_item(), ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-e>'] = cmp.mapping.abort(),
  },
  sources = cmp.config.sources({ { name = 'nvim_lsp' }, { name = 'path' } }, { { name = 'buffer' } }),
})
vim.diagnostic.config({ virtual_text = false, signs = true, underline = true, float = { border = 'rounded' } })
vim.lsp.config('*', { capabilities = require('cmp_nvim_lsp').default_capabilities() })
vim.lsp.config('nixd', {
  cmd = { 'nixd' }, filetypes = { 'nix' }, root_markers = { 'flake.nix', '.git' },
  settings = { nixd = { formatting = { command = { 'nixfmt' } } } },
})
vim.lsp.enable('nixd')
-- Keep native gd, K and Neovim's gr* LSP bindings; additions live under leader.
map('<leader>cg', telescope.lsp_definitions, 'Definitions')
map('<leader>cR', telescope.lsp_references, 'References')
map('<leader>ca', vim.lsp.buf.code_action, 'Code actions')
map('<leader>cr', vim.lsp.buf.rename, 'Rename')
map('<leader>cf', function() vim.lsp.buf.format({ async = false }) end, 'Format')
map('<leader>cd', telescope.diagnostics, 'Diagnostics')
map('<leader>ch', vim.lsp.buf.hover, 'Documentation')
map('<leader>cv', '<cmd>Direnv reload<cr>', 'Reload direnv')
local group = vim.api.nvim_create_augroup('NeonFlux', { clear = true })
vim.api.nvim_create_autocmd('BufWritePre', { group = group, pattern = '*.nix', callback = function(event)
  if #vim.lsp.get_clients({ bufnr = event.buf, name = 'nixd' }) > 0 then
    vim.lsp.buf.format({ bufnr = event.buf, name = 'nixd', timeout_ms = 3000 })
  end
end })
vim.api.nvim_create_autocmd('FileType', { group = group,
  pattern = { 'nix', 'lua', 'sh', 'json', 'python', 'markdown', 'vim', 'help' },
  callback = function() vim.treesitter.start() end,
})
vim.api.nvim_create_autocmd('TextYankPost', { group = group, callback = function() vim.hl.on_yank() end })
vim.api.nvim_create_autocmd('FocusGained', { group = group, command = 'checktime' })

-- Plain Markdown vault; never convert or modify existing Org notes.
local notes = vim.fn.expand(require('neon-flux-settings').notesDirectory)
for _, dir in ipairs({ '', '/daily', '/projects', '/knowledge', '/templates', '/attachments' }) do
  vim.fn.mkdir(notes .. dir, 'p')
end
local seeds = {
  ['inbox.md'] = '# Inbox\n\n',
  ['templates/knowledge.md'] = '# {{title}}\n\n## Summary\n\n## Example\n\n## Pitfalls\n\n## Related\n',
  ['templates/project.md'] = '# {{title}}\n\n## Goal\n\n## Next actions\n\n- [ ] \n\n## Decisions\n\n## References\n',
  ['templates/daily.md'] = '# {{date}}\n\n## Focus\n\n- [ ] \n\n## Log\n\n## Learned\n',
}
for name, content in pairs(seeds) do
  local fd, err = vim.uv.fs_open(notes .. '/' .. name, 'wx', 384)
  if fd then
    local ok, write_err = vim.uv.fs_write(fd, content, 0)
    vim.uv.fs_close(fd)
    assert(ok, write_err)
  elseif not tostring(err):find('EEXIST', 1, true) then error(err) end
end
-- The plugin otherwise maps normal-mode Enter: keep native bindings intact.
vim.g.obsidian_default_keymap = false
require('obsidian').setup({
  legacy_commands = false,
  workspaces = { { name = 'notes', path = notes } },
  notes_subdir = 'knowledge', new_notes_location = 'notes_subdir',
  picker = { name = 'telescope.nvim' },
  link = { style = 'markdown', format = 'relative' },
  frontmatter = { enabled = false },
  note = { template = 'knowledge.md' },
  templates = { folder = 'templates' },
  daily_notes = { folder = 'daily', date_format = 'YYYY-MM-DD',
    template = 'daily.md', default_tags = {}, workdays_only = false },
  attachments = { folder = 'attachments' },
  ui = { enable = false },
  footer = { enabled = false },
  statusline = { enabled = false },
})
map('<leader>nc', function() vim.cmd.edit(vim.fn.fnameescape(notes .. '/inbox.md')) end, 'Capture in inbox')
map('<leader>nn', '<cmd>Obsidian new<cr>', 'New knowledge note')
map('<leader>nd', '<cmd>Obsidian today<cr>', 'Today’s daily note')
map('<leader>nf', '<cmd>Obsidian quick_switch<cr>', 'Find notes (Telescope)')
map('<leader>ns', '<cmd>Obsidian search<cr>', 'Search notes (Telescope)')
map('<leader>ni', '<cmd>Obsidian link<cr>', 'Insert note link')
map('<leader>nb', '<cmd>Obsidian backlinks<cr>', 'Backlinks')
map('<leader>nt', '<cmd>Obsidian template<cr>', 'Insert template')
map('<leader>nl', '<cmd>Obsidian follow_link<cr>', 'Follow note link')
map('<leader>nx', '<cmd>Obsidian toggle_checkbox<cr>', 'Toggle task checkbox')
map('<leader>no', function() telescope.find_files({ cwd = notes, search_dirs = { notes },
  find_command = { 'rg', '--files', '--glob', '*.md' } }) end, 'Browse Markdown notes')
map('<leader>na', function() telescope.find_files({ cwd = notes .. '/daily' }) end, 'Browse daily notes')
vim.api.nvim_create_autocmd('FileType', { group = group, pattern = 'markdown', callback = function()
  vim.opt_local.wrap = true
  vim.opt_local.linebreak = true
  vim.opt_local.spell = true
  vim.opt_local.number = false
  vim.opt_local.relativenumber = false
end })
