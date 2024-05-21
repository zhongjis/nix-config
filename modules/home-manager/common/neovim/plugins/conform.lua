local conform = require("conform")

conform.setup({
  notify_on_error = false,
  format_on_save = function(bufnr)
    -- Disable "format_on_save lsp_fallback" for languages that don't
    -- have a well standardized coding style. You can add additional
    -- languages here or re-enable it for the disabled ones.
    local disable_filetypes =
      { c = true, cpp = true, typescript = true, javascript = true }
    return {
      timeout_ms = 500,
      lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
    }
  end,
  formatters_by_ft = {
    lua = { "stylua" },
    nix = { "alejandra" },
    sh = { "shfmt" },
    javascript = { "prettierd" },
    typescript = { "prettierd" },
    yaml = { "prettierd" },
    markdown = { "prettierd" },
  },
})

conform.formatters.stylua = {
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
}

conform.formatters.shfmt = {
  prepend_args = function(self, ctx)
    return {
      "-i",
      2,
      "-ci",
    }
  end,
}

-- TODO: setup with more styles
-- conform.formatters.prettierd = {
--   prepend_args = function(self, ctx)
--     return {}
--   end,
-- }
