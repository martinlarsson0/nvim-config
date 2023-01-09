vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", ":Rex<CR>")

-- Allow moving selected lines in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Allow cursor to remain in same space when taking line below and appending
-- to current line
vim.keymap.set("n", "J", "mzJ`z")

-- Keep cursor in the middle of page when jumping
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Keep cursor in the middle of the page when searching
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Paste over selected code but make sure that deleted code enters void
-- register, allowing me to keep my current paste
vim.keymap.set("x", "<leader>p", [["_dP]])

-- More delete to void register
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

-- Supposed to allow you to paste to the system clipboard register, however
-- it is broken on WSL linux, making the terminal freeze
-- vim.keymap.set({"n", "v"}, "<leader>y", [["+y]])
-- vim.keymap.set("n", "<leader>Y", [["+Y]])


-- This is going to get me cancelled
vim.keymap.set("i", "<C-c>", "<Esc>")

-- Apparently "Q" is the worst place in the universe, so we avoid it
vim.keymap.set("n", "Q", "<nop>")

-- Use tmux to be able to go to another session / another project, have to
-- look into how to get this to work on WSL and mac?
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

-- Format file
vim.keymap.set("n", "<leader>f", ':Format<CR>')

-- Quick fix naviation?
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

-- Replace current word
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Create an executable, useful for bash but maybe other times as well??
-- vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- tagbar
vim.keymap.set("n", "<F8>", ":TagbarToggle<CR>")

-- Tests
vim.keymap.set("n", "<F1>", ":TestNearest<CR>")
vim.keymap.set("n", "<F2>", ":TestFile<CR>")
vim.keymap.set("n", "<F3>", ":TestLast<CR>")
vim.keymap.set("n", "<F4>", ":TestVisit<CR>")

-- Allow exit terminal mode with esc
vim.keymap.set("t", "<esc>", "<C-\\><C-N>")
