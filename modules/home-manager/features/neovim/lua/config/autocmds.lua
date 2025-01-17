vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  desc = "Set file type for JenkinsFile",
  group = vim.api.nvim_create_augroup("JenkinsFileFix", { clear = true }),
  pattern = "Jenkinsfile*",
  command = "set filetype=groovy",
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
    if
      filetype ~= "oil"
      and buftype ~= nil
      and buftype ~= ""
      and buftype ~= "nofile"
      and filetype ~= "harpoon"
      and filetype ~= "trouble"
    then
      vim.cmd("silent wa")
    end
  end,
})

vim.api.nvim_create_user_command("FormatDisable", function(args)
  if args.bang then
    -- FormatDisable! will disable formatting just for this buffer
    vim.b.disable_autoformat = true
  else
    vim.g.disable_autoformat = true
  end
end, {
  desc = "Disable autoformat-on-save",
  bang = true,
})
vim.api.nvim_create_user_command("FormatEnable", function()
  vim.b.disable_autoformat = false
  vim.g.disable_autoformat = false
end, {
  desc = "Re-enable autoformat-on-save",
})
