return {
  "folke/trouble.nvim",
  opts = {}, -- for default options, refer to the configuration section for custom setup.
  cmd = "Trouble",
  keys = {
    {
      "<leader>xx",
      "<cmd>Trouble diagnostics toggle<cr>",
      desc = "Diagnostics (Trouble)",
    },
    {
      "<leader>xX",
      "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
      desc = "Buffer Diagnostics (Trouble)",
    },
    {
      "<leader>tX",
      "<cmd>Trouble symbols toggle focus=false<cr>",
      desc = "[T]oggle Trouble Symbols",
    },
    {
      "<leader>xL",
      "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
      desc = "LSP Definitions / references / ... (Trouble)",
    },
    {
      "<leader>xl",
      "<cmd>Trouble loclist toggle<cr>",
      desc = "Location List (Trouble)",
    },
    {
      "<leader>xq",
      "<cmd>Trouble qflist toggle<cr>",
      desc = "Quickfix List (Trouble)",
    },
    {
      "]x",
      require("trouble").next({ skip_groups = true, jump = true }),
      desc = "[T]rouble Next)",
    },
    {
      "[x",
      require("trouble").prev({ skip_groups = true, jump = true }),
      desc = "[T]rouble Next)",
    },
  },
}
