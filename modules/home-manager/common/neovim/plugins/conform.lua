-- TODO:
-- 1. better lua format
-- 2. nix format
require("conform").setup({
  notify_on_error = false,
  format_on_save = function(bufnr)
    -- Disable "format_on_save lsp_fallback" for languages that don't
    -- have a well standardized coding style. You can add additional
    -- languages here or re-enable it for the disabled ones.
    local disable_filetypes = { c = true, cpp = true }
    return {
      timeout_ms = 500,
      lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
    }
  end,
  formatters_by_ft = {
    lua = { "stylua" },
    nix = { "nixpkgs_fmt" },
  },
})

require("conform").formatters.stylua = {
  prepend_args = function(self, ctx)
    return {
      "--indent-type",
      "Spaces",
      "--indent-width",
      2,
      "--column-width",
      120,
      "--sort-requires",
    }
  end,
}
