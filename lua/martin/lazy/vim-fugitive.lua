return {
	"tpope/vim-fugitive",
	dependencies = { "tpope/vim-rhubarb" },
	lazy = false,
	config = function()
		vim.keymap.set("n", "<leader>gs", vim.cmd.Git)
		vim.cmd([[ command! -nargs=1 Browse silent exec '!open "<args>"' ]])
	end,
}
