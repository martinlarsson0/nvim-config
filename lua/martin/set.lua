-- Enable line numbers
vim.opt.nu = true

-- Enable relative line numbers
vim.opt.relativenumber = true

-- 4 space indents as default
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Enable smart indent
vim.opt.smartindent = true

-- No linewrap
vim.opt.wrap = false

-- Disable backups, but enable long running undos
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

-- Disable "sticky" search highlighting
vim.opt.hlsearch = false

-- Enable search highlighting
vim.opt.incsearch = true

-- Something about gui colors
vim.opt.termguicolors = true

-- Max 8 line towards the bottom except for end of file
vim.opt.scrolloff = 8

vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

-- Fast update time
vim.opt.updatetime = 50

-- Set a color column at 80 chars
vim.opt.colorcolumn = "80"

-- Set leaderkey
vim.g.mapleader = " "

-- Always copy to clipboard
vim.o.clipboard = "unnamedplus"
