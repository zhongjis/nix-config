local harpoon = require("harpoon")

return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    {
      "<leader>a",
      function()
        harpoon:list():add()
      end,
      desc = "Harpoon: [a]dd file to list",
    },
    {
      "<leader>h",
      function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end,
      desc = "[H]arpoon: quick menu",
    },
    {
      "<c-h>",
      function()
        harpoon:list():select(1)
      end,
      desc = "Harpoon: go to file 1",
    },
    {
      "<c-j>",
      function()
        harpoon:list():select(2)
      end,
      desc = "Harpoon: go to file 2",
    },
    {
      "<c-k>",
      function()
        harpoon:list():select(3)
      end,
      desc = "Harpoon: go to file 3",
    },
    {
      "<c-l>",
      function()
        harpoon:list():select(4)
      end,
      desc = "Harpoon: go to file 4",
    },
    {
      "<leader>f",
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end,
      mode = "",
      desc = "[F]ormat buffer",
    },
  },
}
