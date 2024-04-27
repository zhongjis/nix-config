local actions = require("telescope.actions")

local open_with_trouble = require("trouble.sources.telescope").open
-- Use this to add more results without clearing the trouble list
local add_to_trouble = require("trouble.sources.telescope").add

local telescope = require("telescope")

telescope.setup({
  -- You can put your default mappings / updates / etc. in here
  --  All the info you're looking for is in `:help telescope.setup()`
  --
  defaults = {
    mappings = {
      i = {
        ["<c-t>"] = open_with_trouble,
        ["<c-a>"] = add_to_trouble,
      },
      n = {
        ["<c-t>"] = open_with_trouble,
        ["<c-a>"] = add_to_trouble,
      },
    },
  },
  -- pickers = {}
  extensions = {
    ["ui-select"] = {
      require("telescope.themes").get_dropdown(),
    },
  },
})

-- Enable Telescope extensions if they are installed
pcall(require("telescope").load_extension, "fzf")
pcall(require("telescope").load_extension, "ui-select")
