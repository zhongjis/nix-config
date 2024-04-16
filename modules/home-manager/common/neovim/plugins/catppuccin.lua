require("catppuccin").setup({
  flavour = "mocha",
  integrations = {
    cmp = true,
    gitsigns = true,
    nvimtree = false,
    treesitter = true,
    mini = {
      enabled = true,
      indentscope_color = "",
    },
    which_key = true,
    fidget = true,
    harpoon = true,
    mason = true,
  },
})
