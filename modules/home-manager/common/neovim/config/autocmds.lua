vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  desc = "Set file type for terraform",
  group = vim.api.nvim_create_augroup("TerraformFix", { clear = true }),
  pattern = "*.tf,*.tfvars",
  command = "set filetype=terraform",
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  desc = "Set file type for hcl",
  group = vim.api.nvim_create_augroup("HclFix", { clear = true }),
  pattern = "*.hcl,.terraformrc,terraform.rc",
  command = "set filetype=hcl",
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  desc = "Set file type for terraform state",
  group = vim.api.nvim_create_augroup("HclFix", { clear = true }),
  pattern = "*.tfstate,*.tfstate.backup",
  command = "set filetype=json",
})

vim.api.nvim_create_autocmd("VimResized", {
  desc = "Auto resize panes when window resized",
  group = vim.api.nvim_create_augroup("AutoResize", { clear = true }),
  pattern = "*",
  command = "wincmd =",
})

vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, {
  desc = "Auto save when leave buffer",
  group = vim.api.nvim_create_augroup("AutoSaveBuffer", { clear = true }),
  pattern = "*",
  callback = function()
    -- Get the file type and buffer type of the current buffer
    local filetype = vim.bo.filetype
    local buftype = vim.bo.buftype

    -- If the file type is not 'oil' and the buffer is not a 'nofile' buffer, save the file
    if filetype ~= "oil" and buftype ~= "nofile" then
      vim.cmd("silent wa")
    end
  end,
})
