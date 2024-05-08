-- highlight yank
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
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

-- Auto save when leave buffer
vim.api.nvim_create_autocmd("BufLeave", {
  pattern = "*",
  callback = function()
    -- Check the filetype of the current buffer
    if vim.bo.filetype ~= "oil" then
      -- Only save the buffer if it's not an 'oil' filetype
      vim.cmd("silent! update")
    end
  end,
})
