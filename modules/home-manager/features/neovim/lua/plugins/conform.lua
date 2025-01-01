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
        prepend_args = function(self, ctx)
          return {
            "--indent-type",
            "Spaces",
            "--indent-width",
            2,
            "--column-width",
            85,
            "--sort-requires",
          }
        end,
      },
      black = {
        prepend_args = function(self, ctx)
          return {
            "--line-length",
            79,
          }
        end,
      },
      shfmt = {
        prepend_args = function(self, ctx)
          return {
            "-i",
            2,
            "-ci",
          }
        end,
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
    },
  },
}
