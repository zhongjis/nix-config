-- TODO: update format buffer toggle key
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

return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>f",
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end,
      mode = "",
      desc = "[F]ormat buffer",
    },
    {
      "<leader>tf",
      function()
        if vim.b.disable_autoformat or vim.g.disable_autoformat then
          vim.cmd("FormatEnable")
          vim.notify("AutoFormt Enabled")
        else
          vim.cmd("FormatDisable")
          vim.notify("AutoFormt Disabled")
        end
      end,
      mode = "n",
      desc = "Conform: Toggle [F]ormat",
    },
  },
  opts = {
    notify_on_error = false,
    format_on_save = function(bufnr)
      -- Disable with a global or buffer-local variable
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return
      end

      -- Disable "format_on_save lsp_fallback" for languages that don't
      -- have a well standardized coding style. You can add additional
      -- languages here or re-enable it for the disabled ones.
      local disable_filetypes =
        { c = true, cpp = true, typescript = true, javascript = true, yaml = true }
      return {
        timeout_ms = 500,
        lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
      }
    end,
    formatters = {
      stylua = {
        prepend_args = {
          "--indent-type",
          "Spaces",
          "--indent-width",
          2,
          "--column-width",
          85,
          "--sort-requires",
        },
      },
      black = {
        prepend_args = {
          "--line-length",
          85,
        },
      },
      shfmt = {
        args = {
          "-i",
          2,
          "-ci",
        },
      },
    },
    formatters_by_ft = {
      lua = { "stylua" },
      nix = { "alejandra" },
      sh = { "shfmt" },
      javascript = { "prettierd" },
      typescript = { "prettierd" },
      yaml = { "prettierd" },
      markdown = { "prettierd" },
      python = { "black" },
      css = { "prettierd" },
      terraform = { "terraform_fmt" },
    },
  },
}
