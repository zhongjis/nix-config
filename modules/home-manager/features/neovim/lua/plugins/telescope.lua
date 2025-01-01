return { -- Fuzzy Finder (files, lsp, etc)
  "nvim-telescope/telescope.nvim",
  event = "VimEnter",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { -- If encountering errors, see telescope-fzf-native README for installation instructions
      "nvim-telescope/telescope-fzf-native.nvim",

      -- `build` is used to run some command when the plugin is installed/updated.
      -- This is only run then, not every time Neovim starts up.
      build = "make",

      -- `cond` is a condition used to determine whether this plugin should be
      -- installed and loaded.
      cond = function()
        return vim.fn.executable("make") == 1
      end,
    },

    -- Useful for getting pretty icons, but requires a Nerd Font.
    { "nvim-tree/nvim-web-devicons", enabled = true },
  },
  config = function()
    local actions = require("telescope.actions")

    local telescope = require("telescope")

    telescope.setup({
      -- You can put your default mappings / updates / etc. in here
      --  All the info you're looking for is in `:help telescope.setup()`
      --
      defaults = {
        mappings = {
          i = {
            ["<c-q>"] = actions.send_to_qflist,
            ["<c-a>"] = actions.add_to_qflist,
          },
          n = {
            ["<c-q>"] = actions.send_to_qflist,
            ["<c-a>"] = actions.add_to_qflist,
          },
        },
      },
    })

    -- Enable Telescope extensions if they are installed
    pcall(require("telescope").load_extension, "fzf")

    -- See `:help telescope.builtin`
    local map = function(keys, func, desc)
      vim.keymap.set("n", keys, func, { desc = desc, noremap = true })
    end
    local builtin = require("telescope.builtin")
    map("<leader>sh", builtin.help_tags, "[S]earch [H]elp")
    map("<leader>sf", builtin.find_files, "[S]earch [F]iles")
    map("<leader>ss", builtin.builtin, "[S]earch [S]elect Telescope")
    map("<leader>sw", builtin.grep_string, "[S]earch current [W]ord")
    map("<leader>sg", builtin.live_grep, "[S]earch by [G]rep")
    map("<leader>sr", builtin.resume, "[S]earch [R]esume")
    map(
      "<leader>/",
      builtin.current_buffer_fuzzy_find,
      "[/] Fuzzily search in current buffer"
    )
    map("<leader>s/", function()
      builtin.live_grep({
        grep_open_files = true,
        prompt_title = "Live Grep in Open Files",
      })
    end, "[S]earch [/] in Open Files")
  end,
}
