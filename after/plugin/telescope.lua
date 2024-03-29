local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>pf", builtin.find_files, { desc = "[P]roject [F]ind" })
vim.keymap.set("n", "<leader>phf", "<CMD>Telescope find_files no_ignore=true hidden=true<CR>")
vim.keymap.set("n", "<C-p>", builtin.git_files, { desc = "Find git files" })
vim.keymap.set("n", "<leader>ps", builtin.live_grep)
vim.keymap.set("n", "<leader>pr", builtin.resume)
vim.keymap.set("n", "<leader>pp", builtin.pickers)
vim.keymap.set("n", "<leader>pg", builtin.git_status)

local ts_select_dir_for_grep = function(prompt_bufnr)
  local action_state = require("telescope.actions.state")
  local fb = require("telescope").extensions.file_browser
  local live_grep = require("telescope.builtin").live_grep
  local current_line = action_state.get_current_line()

  fb.file_browser({
    files = false,
    depth = false,
    attach_mappings = function(prompt_bufnr)
      require("telescope.actions").select_default:replace(function()
        local entry_path = action_state.get_selected_entry().Path
        local dir = entry_path:is_dir() and entry_path or entry_path:parent()
        local relative = dir:make_relative(vim.fn.getcwd())
        local absolute = dir:absolute()

        live_grep({
          results_title = relative .. "/",
          cwd = absolute,
          default_text = current_line,
        })
      end)

      return true
    end,
  })
end

require("telescope").setup({
  pickers = {
    live_grep = {
      mappings = {
        i = {
          ["<C-f>"] = ts_select_dir_for_grep,
        },
        n = {
          ["<C-f>"] = ts_select_dir_for_grep,
        },
      },
    },
  },
  defaults = {
      cache_picker = {
          num_pickers = 10,
      },
  },
})

require('telescope').load_extension('fzf')
