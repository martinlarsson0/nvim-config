-- local lsp = require("lsp-zero")
-- lsp.preset("recommended")
--
-- -- Fix Undefined global 'vim'
-- lsp.configure('lua_ls', {
--     settings = {
--         Lua = {
--             globals = { 'vim' },
--             diagnostics = {
--                 globals = { 'vim' }
--             }
--         }
--     }
-- })
--
--
-- local cmp = require("cmp")
-- local cmp_select = { behavior = cmp.SelectBehavior.Select }
-- local cmp_mappings = lsp.defaults.cmp_mappings({
--     ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
--     ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
--     ["<CR>"] = cmp.mapping.confirm({ select = true }),
--     ["<C-Space>"] = cmp.mapping.complete(),
-- })
--
--
-- lsp.setup_nvim_cmp({
--     mapping = cmp_mappings
-- })
--
-- lsp.set_preferences({
--     suggest_lsp_servers = false,
--     sign_icons = {
--         error = 'E',
--         warn = 'W',
--         hint = 'H',
--         info = 'I'
--     }
-- })
--
-- lsp.on_attach(function(client, bufnr)
--     local opts = { buffer = bufnr, remap = false }
--
--     vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
--     vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
--     vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, opts)
--     vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, opts)
--     vim.keymap.set("n", "[d", vim.diagnostic.goto_next, opts)
--     vim.keymap.set("n", "]d", vim.diagnostic.goto_prev, opts)
--     vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, opts)
--     vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references, opts)
--     vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, opts)
--     vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)
-- end)
--
function filter(arr, func)
    -- Filter in place
    -- https://stackoverflow.com/questions/49709998/how-to-filter-a-lua-array-inplace
    local new_index = 1
    local size_orig = #arr
    for old_index, v in ipairs(arr) do
        if func(v, old_index) then
            arr[new_index] = v
            new_index = new_index + 1
        end
    end
    for i = new_index, size_orig do arr[i] = nil end
end

function filter_diagnostics(diagnostic)
    -- Only filter out Pyright stuff for now
    if diagnostic.source ~= "Pyright" then
        return true
    end

    -- Allow kwargs to be unused, sometimes you want many functions to take the
    -- same arguments but you don't use all the arguments in all the functions,
    -- so kwargs is used to suck up all the extras
    -- if diagnostic.message == '"kwargs" is not accessed' then
    -- 	return false
    -- end

    -- Allow variables starting with an underscore
    -- if string.match(diagnostic.message, '"_.+" is not accessed') then
    -- 	return false
    -- end

    -- Remove diagnostics which start with "Cannot access member"
    if (
        string.match(diagnostic.message, 'Cannot access member.+')
        or string.match(diagnostic.message, 'Cannot assign member.+') 
        or  string.match(diagnostic.message, 'Argument of type.+') 
        or string.match(diagnostic.message, '"kwargs" is not accessed') 
        or string.match(diagnostic.message, '"args" is not accessed')
    ) then
        return false
    end

    return true
end

function custom_on_publish_diagnostics(a, params, client_id, c, config)
    filter(params.diagnostics, filter_diagnostics)
    vim.lsp.diagnostic.on_publish_diagnostics(a, params, client_id, c, config)
end

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
    custom_on_publish_diagnostics, {})
--
-- lsp.setup()
--
vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    update_in_insert = false,
    underline = false,
    severity_sort = true,
    float = {
        focusable = false,
        style = 'minimal',
        border = 'rounded',
        source = 'always',
        header = '',
        prefix = '',
    },
})
