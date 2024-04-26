-- TODO: possibly undo using telescope undo extension?
-- local actions = require("telescope.actions")
-- local trouble = require("trouble.providers.telescope")

require("telescope").setup({
  -- You can put your default mappings / updates / etc. in here
  --  All the info you're looking for is in `:help telescope.setup()`
  --
  -- defaults = {
  --   mappings = {
  --     i = { ["<c-t>"] = trouble.open_with_trouble },
  --     n = { ["<c-t>"] = trouble.open_with_trouble },
  --   },
  -- },
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
