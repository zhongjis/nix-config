return {
  "stevearc/oil.nvim",
  event = "VimEnter",
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {},
  dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
  keys = {
    {
      "<leader>o",
      "<cmd>Oil<cr>",
      desc = "[O]il: Open parent directory",
    },
  },
}
