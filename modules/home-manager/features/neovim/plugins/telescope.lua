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
