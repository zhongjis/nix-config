-- settings
require("trouble").setup({
  auto_refresh = false,
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

-- settings: disable trouble icon
require("trouble.format").formatters.file_icon = function()
  return ""
end

-- keymaps
local map = function(keys, func, desc)
  vim.keymap.set("n", keys, func, { desc = desc, noremap = true })
end

map("<leader>q", "<cmd>Trouble qflist toggle<cr>", "Toggle [Q]uickfix List")
map("]t", function()
  if require("trouble").is_open() then
    require("trouble").next({ skip_groups = true, jump = true })
  else
    local ok, err = pcall(vim.cmd.cnext)
    if not ok then
      vim.notify(err, vim.log.levels.ERROR)
    end
  end
end, "Go to next [T]rouble item")
map("[t", function()
  if require("trouble").is_open() then
    require("trouble").prev({ skip_groups = true, jump = true })
  else
    local ok, err = pcall(vim.cmd.cprev)
    if not ok then
      vim.notify(err, vim.log.levels.ERROR)
    end
  end
end, "Go to previous [T]rouble item")
