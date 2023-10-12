-- disable netrw at the very start of your init.lua (strongly advised)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- set termguicolors to enable highlight groups
vim.opt.termguicolors = true


local function my_on_attach(bufnr)
    local api = require('nvim-tree.api')
    -- Use all default mappings
    api.config.mappings.default_on_attach(bufnr)

    -- Remove ctrl + e mapping
    vim.keymap.del('n', '<C-e>', { buffer = bufnr })
end

-- setup with some options
require("nvim-tree").setup({
    sort_by = "case_sensitive",
    view = {
        adaptive_size = true,
    },
    on_attach = my_on_attach,
    git = {
        enable = true,
        ignore = false,
        timeout = 500,
    },
})

local function open_nvim_tree(data)

    -- buffer is a directory
    local directory = vim.fn.isdirectory(data.file) == 1

    if not directory then
        return
    end

    -- change to the directory
    vim.cmd.cd(data.file)

    -- open the tree
    require("nvim-tree.api").tree.open()
end

vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })
