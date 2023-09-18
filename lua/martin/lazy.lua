local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
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

    -- Gives syntax coloring, might need to add languages
    {'nvim-treesitter/nvim-treesitter', build = ':TSUpdate' },

    -- Long classes/functions context
    'nvim-treesitter/nvim-treesitter-context',

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
    'tpope/vim-fugitive',

    -- LSP
     {
        'VonHeikemen/lsp-zero.nvim',
        dependencies = {
            -- LSP Support
            'neovim/nvim-lspconfig',
            'williamboman/mason.nvim',
            'williamboman/mason-lspconfig.nvim',

            -- Autocompletion
            'hrsh7th/nvim-cmp',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'saadparwaiz1/cmp_luasnip',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-nvim-lua',

            -- Snippets
            'L3MON4D3/LuaSnip',
            'rafamadriz/friendly-snippets',
        }
    },

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

    -- Formatter
    "williamboman/mason.nvim",
    "jose-elias-alvarez/null-ls.nvim",
    "jay-babu/mason-null-ls.nvim",

    -- Testing
     "vim-test/vim-test",

    -- Used primarily for filtering on folders when grepping, hnameother s
    -- namewell
     "nvim-telescope/telescope-file-browser.nvim",

    -- Faster telescope sorting
    { 'nvim-telescope/telescope-fzf-native.nvim',
        build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build'
    },

    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'kyazdani42/nvim-web-devicons', lazy = true }
    },



}

require("lazy").setup(plugins)
