require("mason").setup()
require("mason-null-ls").setup({
    ensure_installed = {
        -- Opt to list sources here, when available in mason.
    },
    automatic_installation = false,
    automatic_setup = true, -- Recommended, but optional
})
require("null-ls").setup({
    sources = {
        -- Anything not supported by mason.
    },
    on_attach = function(client, bufnr)
        if client.supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
            vim.api.nvim_create_autocmd("BufWritePre", {
                group = augroup,
                buffer = bufnr,
                callback = function()
                    -- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
                    vim.lsp.buf.format({ bufnr = bufnr })
                end,
            })
        end
    end,
})

require 'mason-null-ls'.setup_handlers() -- If `automatic_setup` is true.
