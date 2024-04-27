-- highlight yank
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup(
    "kickstart-highlight-yank",
    { clear = true }
  ),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Fix a issue when new .tf file created it auto set filetype
vim.cmd([[ autocmd BufNewFile,BufRead *.tf set filetype=terraform ]])

-- Auto resize panes
vim.api.nvim_create_augroup("AutoResize", { clear = true })

-- Set up the autocommand within the group
vim.api.nvim_create_autocmd("VimResized", {
  group = "AutoResize",
  pattern = "*",
  command = "wincmd =",
})
