vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

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

-- This is going to get me cancelled
vim.keymap.set("i", "<C-c>", "<Esc>")

-- Apparently "Q" is the worst place in the universe, so we avoid it
vim.keymap.set("n", "Q", "<nop>")

-- Format file
vim.keymap.set("n", "<leader>f", ":LspZeroFormat<CR>")

-- Quick fix naviation?
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

-- Replace current word
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Tests
vim.keymap.set("n", "<leader>1", ":TestNearest<CR>")
vim.keymap.set("n", "<leader>2", ":TestFile<CR>")
vim.keymap.set("n", "<leader>3", ":TestLast<CR>")
vim.keymap.set("n", "<leader>4", ":TestVisit<CR>")

-- Allow exit terminal mode with esc
vim.keymap.set("t", "<esc>", "<C-\\><C-N>")

-- Keybind for splitting and starting a terminal
vim.keymap.set("n", "<leader>t", ":split<CR>:terminal ")

-- nvim-tree
vim.keymap.set("n", "<leader>=", ":NvimTreeToggle<CR>")
vim.keymap.set("n", "<leader>pv", ":NvimTreeFindFile<CR>")
-- vim.keymap.set("n", "<F3>", ":NvimTreeRefresh<CR>")
vim.keymap.set("n", "<leader>-", ":NvimTreeCollapseKeepBuffers<CR>")

--"Show LSP references"
vim.keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>") -- show definition, references

--"Go to declaration"
vim.keymap.set("n", "gD", vim.lsp.buf.declaration) -- go to declaration

--"Show LSP definitions"
vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>") -- show lsp definitions

--"Show LSP implementations"
vim.keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>") -- show lsp implementations

--"Show LSP type definitions"
vim.keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>") -- show lsp type definitions

--"See available code actions"
vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action) -- see available code actions, in visual mode will apply to selection

--"Smart rename"
vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename) -- smart rename

-- Diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous [D]iagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next [D]iagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic [E]rror messages" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

--"Show buffer diagnostics"
vim.keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>") -- show  diagnostics for file

--"Restart LSP"
vim.keymap.set("n", "<leader>rs", ":LspRestart<CR>") -- mapping to restart lsp if necessary

-- Remove big jump behaviour of SHIFT arrow key in normal and visual mode
vim.keymap.set("n", "<S-Up>", "<Up>")
vim.keymap.set("n", "<S-Down>", "<Down>")
vim.keymap.set("n", "<S-Right>", "<Right>")
vim.keymap.set("n", "<S-Left>", "<Left>")
vim.keymap.set("v", "<S-Up>", "<Up>")
vim.keymap.set("v", "<S-Down>", "<Down>")
vim.keymap.set("v", "<S-Right>", "<Right>")
vim.keymap.set("v", "<S-Left>", "<Left>")
