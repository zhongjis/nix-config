vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  desc = "Fix a issue when new .tf file created it auto set filetype",
  group = vim.api.nvim_create_augroup("TerraformFix", { clear = true }),
  pattern = "*.tf",
  command = "set filetype=terraform",
})

vim.api.nvim_create_autocmd("VimResized", {
  desc = "Auto resize panes when window resized",
  group = vim.api.nvim_create_augroup("AutoResize", { clear = true }),
  pattern = "*",
  command = "wincmd =",
})

vim.api.nvim_create_autocmd("BufLeave", {
  desc = "Auto save when leave buffer",
  group = vim.api.nvim_create_augroup("AutoSaveBuffer", { clear = true }),
  pattern = "*",
  callback = function()
    -- Check the filetype of the current buffer
    if vim.bo.filetype ~= "oil" then
      -- Only save the buffer if it's not an 'oil' filetype
      vim.cmd("silent! update")
    end
  end,
})
