require("trouble").setup({
  modes = {
    telescope = {
      sort = { "pos", "filename", "severity", "message" },
    },
    quickfix = {
      sort = { "pos", "filename", "severity", "message" },
    },
    qflist = {
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

require("trouble.format").formatters.file_icon = function()
  return ""
end
