return {
  "folke/zen-mode.nvim",
  keys = {
    {
      "<leader>tz",
      function()
        require("zen-mode").toggle({ width = 0.85 })
      end,
      desc = "Toggle [Z]en Mode",
    },
  },
}
