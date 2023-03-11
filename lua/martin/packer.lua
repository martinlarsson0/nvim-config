-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'

    -- Telescope, used for project, git and grep search
    use {
        'nvim-telescope/telescope.nvim', tag = '0.1.0',
        -- or                            , branch = '0.1.x',
        requires = { {'nvim-lua/plenary.nvim'} }
    }

    -- Theme of editor
    use({
        'rose-pine/neovim',
        as = 'rose-pine',
        config = function()
            vim.cmd('colorscheme rose-pine')
        end
    })

    use {
        'nvim-tree/nvim-tree.lua',
        requires = {
            'nvim-tree/nvim-web-devicons', -- optional, for file icons
        },
        tag = 'nightly' -- optional, updated every week. (see issue #1193)
    }

    -- Gives syntax coloring, might need to add languages
    use('nvim-treesitter/nvim-treesitter', {run = ':TSUpdate'})

    -- Long classes/functions context
    use('nvim-treesitter/nvim-treesitter-context')

    -- Allows me to bookmark and easily move between different
    -- files. Might need more keybinds if 4 windows turns out
    -- to be too little
    use('ThePrimeagen/harpoon')

    -- Allows me to see a tree representation of changes made
    -- to a file, as well as go back in time and keep several
    -- "branches" of my code
    use('mbbill/undotree')

    -- Git integration
    use('tpope/vim-fugitive')

    -- LSP
    use {
        'VonHeikemen/lsp-zero.nvim',
        requires = {
            -- LSP Support
            {'neovim/nvim-lspconfig'},
            {'williamboman/mason.nvim'},
            {'williamboman/mason-lspconfig.nvim'},

            -- Autocompletion
            {'hrsh7th/nvim-cmp'},
            {'hrsh7th/cmp-buffer'},
            {'hrsh7th/cmp-path'},
            {'saadparwaiz1/cmp_luasnip'},
            {'hrsh7th/cmp-nvim-lsp'},
            {'hrsh7th/cmp-nvim-lua'},

            -- Snippets
            {'L3MON4D3/LuaSnip'},
            {'rafamadriz/friendly-snippets'},
        }
    }

    -- Show high-level view of file contents
    use("preservim/tagbar")

    -- Git file diffs
    use("airblade/vim-gitgutter")

    -- Language aware comments
    use("numToStr/Comment.nvim")

    -- Project specific settings
    use {
        "klen/nvim-config-local",
        config = function()
            require('config-local').setup {
                -- Default configuration (optional)
                config_files = { ".vimrc.lua", ".vimrc" },  -- Config file patterns to load (lua supported)
                hashfile = vim.fn.stdpath("data") .. "/config-local", -- Where the plugin keeps files data
                autocommands_create = true,                 -- Create autocommands (VimEnter, DirectoryChanged)
                commands_create = true,                     -- Create commands (ConfigSource, ConfigEdit, ConfigTrust, ConfigIgnore)
                silent = false,                             -- Disable plugin messages (Config loaded/ignored)
                lookup_parents = false,                     -- Lookup config files in parent directories
            }
        end
    }

    -- Formatter
    use {
        "williamboman/mason.nvim",
        "jose-elias-alvarez/null-ls.nvim",
        "jay-babu/mason-null-ls.nvim",
    }

    -- Testing
    use {"vim-test/vim-test"}

    -- Used primarily for filtering on folders when grepping, has other uses
    -- as well
    use {"nvim-telescope/telescope-file-browser.nvim"}
 
    -- Faster telescope sorting
    use {'nvim-telescope/telescope-fzf-native.nvim', run = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build' }
end)
