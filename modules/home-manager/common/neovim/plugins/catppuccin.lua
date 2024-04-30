-- NOTE: https://github.com/catppuccin/nvim
require("catppuccin").setup({
  flavour = "mocha",
  integrations = {
    gitsigns = true,
    -- nvimtree = true,
    treesitter = true,
    mini = {
      enabled = true,
      indentscope_color = "",
    },
    which_key = true,
    fidget = true,
    harpoon = true,
    mason = true,
    -- noice = true,
    -- notify = true,
    lsp_trouble = true,
  },
})
