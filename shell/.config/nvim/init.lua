-- Single-file neovim config. Plugin-free; colors come from terminal palette.

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- UI
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.signcolumn = 'yes'
vim.opt.scrolloff = 4
vim.opt.sidescrolloff = 8
vim.opt.showmode = false
vim.opt.termguicolors = true

-- Indentation defaults — 2 spaces, soft tabs.
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.smartindent = true

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = true

-- Files
vim.opt.hidden = true
vim.opt.undofile = true
vim.opt.undodir = vim.fn.expand('~/.local/state/nvim/undo')
vim.opt.swapfile = false
vim.opt.backup = false

-- Splits open to the right and below — feels natural with reading order.
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Mouse + system clipboard.
vim.opt.mouse = 'a'
vim.opt.clipboard = 'unnamedplus'

vim.opt.wildmode = 'longest:full,full'

-- Per-filetype indentation overrides.
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'python', 'go' },
  callback = function()
    vim.bo.shiftwidth = 4
    vim.bo.tabstop = 4
    vim.bo.softtabstop = 4
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'go',
  callback = function() vim.bo.expandtab = false end,
})

-- Trim trailing whitespace on save, except where it's significant.
vim.api.nvim_create_autocmd('BufWritePre', {
  callback = function()
    local skip = { gitcommit = true, markdown = true, diff = true }
    if skip[vim.bo.filetype] then return end
    local view = vim.fn.winsaveview()
    vim.cmd([[silent! %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

local map = vim.keymap.set
map('n', '<leader>w', '<cmd>write<cr>', { desc = 'Write buffer' })
map('n', '<leader>q', '<cmd>quit<cr>', { desc = 'Quit window' })
map('n', '<leader>h', '<cmd>nohlsearch<cr>', { desc = 'Clear search highlight' })
map('n', '<C-h>', '<C-w>h')
map('n', '<C-j>', '<C-w>j')
map('n', '<C-k>', '<C-w>k')
map('n', '<C-l>', '<C-w>l')
