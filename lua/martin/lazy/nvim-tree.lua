local function my_on_attach(bufnr)
	local api = require("nvim-tree.api")
	-- Use all default mappings
	api.config.mappings.default_on_attach(bufnr)

	-- Remove ctrl + e mapping
	vim.keymap.del("n", "<C-e>", { buffer = bufnr })
end

local function open_tree_on_start_if_directory(data)
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

return {
	"nvim-tree/nvim-tree.lua",
	dependencies = {
		"kyazdani42/nvim-web-devicons",
		lazy = true, -- optional, for file icons
	},
	version = "1.3.*",
	lazy = false,
	config = function()
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
		vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_tree_on_start_if_directory })
	end,
}
