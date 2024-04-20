return {
	"vim-test/vim-test",
	config = function()
		vim.g["test#python#djangotest#options"] = {
			all = 'DJANGO_SETTINGS_MODULE="kog.config.settings.testing" --keepdb',
		}
		vim.g["test#strategy"] = "neovim"
	end,
}
