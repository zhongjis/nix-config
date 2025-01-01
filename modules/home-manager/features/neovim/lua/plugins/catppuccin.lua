return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  opts = {},
  config = function()
    require("catppuccin").setup({
      flavour = "mocha",
      transparent_background = true,
      integrations = {
        cmp = true,
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
        noice = true,
        notify = true,
        lsp_trouble = true,
      },
    })
  end,
}
