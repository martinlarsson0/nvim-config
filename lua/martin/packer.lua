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

    -- Gives syntax coloring, might need to add languages
    use('nvim-treesitter/nvim-treesitter', {run = ':TSUpdate'})

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
end)
