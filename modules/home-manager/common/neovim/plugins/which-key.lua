require("which-key").setup({
  icons= false
})

require("which-key").add({
  { "", group = "[S]earch" },
  { "", group = "[D]ocument" },
  { "", group = "[C]ode" },
  { "", group = "[R]ename" },
  { "", group = "[W]orkspace" },
  { "", desc = "", hidden = true, mode = { "n", "n", "n", "n", "n" } },
})
