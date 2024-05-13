require("trouble").setup({
  icons = false,
  modes = {
    telescope = {
      sort = { "pos", "filename", "severity", "message" },
    },
    quickfix = {
      sort = { "pos", "filename", "severity", "message" },
    },
    loclist = {
      sort = { "pos", "filename", "severity", "message" },
    },
    todo = {
      sort = { "pos", "filename", "severity", "message" },
    },
  },
})
