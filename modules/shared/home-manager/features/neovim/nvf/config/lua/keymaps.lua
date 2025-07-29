local map = function(keys, func, desc)
  vim.keymap.set("n", keys, func, { desc = desc, noremap = true })
end

map("<Esc>", "<cmd>nohlsearch<CR>", "")

-- continuous indenting
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- do not override register when paste*
vim.keymap.set("x", "p", [["_dP]])

-- diagnostic
map("<leader>e", vim.diagnostic.open_float, "Show diagnostic [E]rror messages")

map("<leader>tf", function()
  if vim.b.disable_autoformat or vim.g.disable_autoformat then
    vim.cmd("FormatEnable")
    vim.notify("AutoFormt Enabled")
  else
    vim.cmd("FormatDisable")
    vim.notify("AutoFormt Disabled")
  end
end, "Toggle [F]ormat")
