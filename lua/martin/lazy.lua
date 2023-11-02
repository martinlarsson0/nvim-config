-- BOOTSTRAP the plugin manager `lazy.nvim`
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lazyIsInstalled = vim.loop.fs_stat(lazypath)
if not lazyIsInstalled then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.runtimepath:prepend(lazypath)

local plugins = {
    -- TOOLING: COMPLETION, DIAGNOSTICS, FORMATTING

    -- Manager for external tools (LSPs, linters, debuggers, formatters)
	-- auto-install of those external tools
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = {
			{ "williamboman/mason.nvim", opts = true },
			{ "williamboman/mason-lspconfig.nvim", opts = true },
		},
		opts = {
			ensure_installed = {
				"pyright", -- LSP for python
				"ruff-lsp", -- linter for python (includes flake8, pep8, etc.)
				"black", -- formatter
				"isort", -- organize imports
				"taplo", -- LSP for toml (for pyproject.toml files)
			},
		},
	},
    --
    -- Setup the LSPs
	-- `gd` and `gr` for goto definition / references
	-- `<leader>c` for code actions (organize imports, etc.)
    {
      "neovim/nvim-lspconfig",
      dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        { "antosha417/nvim-lsp-file-operations", config = true },
      },
      config = function()
            -- import lspconfig plugin
            local lspconfig = require("lspconfig")

            -- import cmp-nvim-lsp plugin
            local cmp_nvim_lsp = require("cmp_nvim_lsp")

            -- used to enable autocompletion (assign to every lsp server config)
            local capabilities = cmp_nvim_lsp.default_capabilities()

            -- Change the Diagnostic symbols in the sign column (gutter)
            -- (not in youtube nvim video)
            local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
            for type, icon in pairs(signs) do
              local hl = "DiagnosticSign" .. type
              vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
            end
			-- setup pyright with completion capabilities
			lspconfig.pyright.setup({
				capabilities = lspCapabilities,
                on_attach = on_attach,
                settings = {
                  python = {
                    analysis = {
                      autoSearchPaths = true,
                      diagnosticMode = "workspace",
                      useLibraryCodeForTypes = true
                    }
                  },
                },
			})

			-- setup taplo with completion capabilities
			lspconfig.taplo.setup({
				capabilities = lspCapabilities,
                on_attach = on_attach,
			})

			-- ruff uses an LSP proxy, therefore it needs to be enabled as if it
			-- were a LSP. In practice, ruff only provides linter-like diagnostics
			-- and some code actions, and is not a full LSP yet.
			-- lspconfig.ruff_lsp.setup({
			-- 	-- organize imports disabled, since we are already using `isort` for that
			-- 	-- alternative, this can be enabled to make `organize imports`
			-- 	-- available as code action
			-- 	settings = {
			-- 		organizeImports = false,
			-- 	},
			-- 	-- disable ruff as hover provider to avoid conflicts with pyright
			-- 	on_attach = function(client) client.server_capabilities.hoverProvider = false end,
			-- })
		end,
	},

    -- Formatting client: conform.nvim
	-- - configured to use black & isort in python
	-- - use the taplo-LSP for formatting in toml
	-- - Formatting is triggered via `<leader>f`, but also automatically on save
	{
		"stevearc/conform.nvim",
		event = "BufWritePre", -- load the plugin before saving
		keys = {
			{
				"<leader>f",
				function() require("conform").format({ lsp_fallback = true }) end,
				desc = "Format",
			},
		},
		opts = {
			formatters_by_ft = {
				-- first use isort and then black
				python = { "isort", "black" },
			},
			-- enable format-on-save
			format_on_save = {
				-- when no formatter is setup for a filetype, fallback to formatting
				-- via the LSP. This is relevant e.g. for taplo (toml LSP), where the
				-- LSP can handle the formatting for us
				lsp_fallback = true,
			},
		},
	},

    -- Completion via nvim-cmp
    {
      "hrsh7th/nvim-cmp",
      dependencies = {
        "hrsh7th/cmp-buffer", -- source for text in buffer
        "hrsh7th/cmp-path", -- source for file system paths
        "L3MON4D3/LuaSnip", -- snippet engine
        "saadparwaiz1/cmp_luasnip", -- for autocompletion
        "rafamadriz/friendly-snippets", -- useful snippets
        "onsails/lspkind.nvim", -- vs-code like pictograms
      },
      config = function()
        local cmp = require("cmp")

        local luasnip = require("luasnip")

        local lspkind = require("lspkind")

        -- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
        require("luasnip.loaders.from_vscode").lazy_load()

        cmp.setup({
          completion = {
            completeopt = "menu,menuone,preview,noselect",
          },
          snippet = { -- configure how nvim-cmp interacts with snippet engine
            expand = function(args)
              luasnip.lsp_expand(args.body)
            end,
          },
          mapping = cmp.mapping.preset.insert({
            ["<C-k>"] = cmp.mapping.select_prev_item(), -- previous suggestion
            ["<C-j>"] = cmp.mapping.select_next_item(), -- next suggestion
            ["<C-b>"] = cmp.mapping.scroll_docs(-4),
            ["<C-f>"] = cmp.mapping.scroll_docs(4),
            ["<TAB>"] = cmp.mapping.complete(), -- show completion suggestions
            ["<C-e>"] = cmp.mapping.abort(), -- close completion window
            ["<CR>"] = cmp.mapping.confirm({ select = false }),
          }),
          -- sources for autocompletion
          sources = cmp.config.sources({
            { name = "nvim_lsp" },
            { name = "luasnip" }, -- snippets
            { name = "buffer" }, -- text within current buffer
            { name = "path" }, -- file system paths
          }),
          -- configure lspkind for vs-code like pictograms in completion menu
          formatting = {
            format = lspkind.cmp_format({
              maxwidth = 50,
              ellipsis_char = "...",
            }),
          },
        })


      end,
    },
	-----------------------------------------------------------------------------
	-- SYNTAX HIGHLIGHTING    -- treesitter for syntax highlighting
	-- - auto-installs the parser for python
	{
		"nvim-treesitter/nvim-treesitter",
		-- automatically update the parsers with every new release of treesitter
		build = ":TSUpdate",
	},

    -- Long classes/functions context
    -- 'nvim-treesitter/nvim-treesitter-context',

	-----------------------------------------------------------------------------
    -- OTHER

    -- f-strings
	-- - auto-convert strings to f-strings when typing `{}` in a string
	-- - also auto-converts f-strings back to regular strings when removing `{}`
	{
		"chrisgrieser/nvim-puppeteer",
		dependencies = "nvim-treesitter/nvim-treesitter",
	},

    -- better indentation behavior
	-- by default, vim has some weird indentation behavior in some edge cases,
	-- which this plugin fixes
	{ "Vimjas/vim-python-pep8-indent" },

    -- Telescope, used for project, git and grep search
     {
        'nvim-telescope/telescope.nvim', version = '0.1.0',
        dependencies = { 'nvim-lua/plenary.nvim' }
    },

    -- Theme of editor
    {
        'rose-pine/neovim',
        name = 'rose-pine',
        config = function()
            vim.cmd('colorscheme rose-pine')
        end
    },

    {
        'nvim-tree/nvim-tree.lua',
        dependencies = {
            'kyazdani42/nvim-web-devicons', lazy = true -- optional, for file icons
        },
        version = 'nightly' -- optional, updated every week. (see issue #1193)
    },

    -- Allows me to bookmark and easily move between different
    -- files. Might need more keybinds if 4 windows turns out
    -- to be too little
    'ThePrimeagen/harpoon',

    -- Vim training
    'ThePrimeagen/vim-be-good',

    -- Allows me to see a tree representation of changes made
    -- to a file, as well as go back in time and keep several
    -- "branches" of my code
    'mbbill/undotree',

    -- Git integration
    {'tpope/vim-fugitive', dependencies = { 'tpope/vim-rhubarb' }},

    -- Copilot
     'zbirenbaum/copilot.lua',

    -- Show high-level view of file contents
    'preservim/tagbar',

    -- Git file diffs
    'airblade/vim-gitgutter',

    -- Language aware comments
    'numToStr/Comment.nvim',

    -- Project specific settings
     {
        "klen/nvim-config-local",
        config = function()
            require('config-local').setup {
                -- Default configuration (optional)
                config_files = { ".vimrc.lua", ".vimrc" }, -- Config file patterns to load (lua supported)
                hashfile = vim.fn.stdpath("data") .. "/config-local", -- Where the plugin keeps files data
                autocommands_create = true, -- Create autocommands (VimEnter, DirectoryChanged)
                commands_create = true, -- Create commands (ConfigSource, ConfigEdit, ConfigTrust, ConfigIgnore)
                silent = false, -- Disable plugin messages (Config loaded/ignored)
                lookup_parents = false, -- Lookup config files in parent directories
            }
        end
    },

    -- Testing
     "vim-test/vim-test",

    -- Used primarily for filtering on folders when grepping, hnameother s
    -- namewell
     "nvim-telescope/telescope-file-browser.nvim",

    -- Faster telescope sorting
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build' },

    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'kyazdani42/nvim-web-devicons', lazy = true }
    },
}

require("lazy").setup(plugins)
vim.g.mapleader = " "
