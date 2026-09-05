local configs = {
  "eslint.config.js", "eslint.config.mjs", "eslint.config.cjs",
  "eslint.config.ts", "eslint.config.mts", "eslint.config.cts",
  ".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.json",
  ".eslintrc.yaml", ".eslintrc.yml",
}

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
  group = vim.api.nvim_create_augroup("ProjectESLint", { clear = true }),
  pattern = { "*.js", "*.mjs", "*.cjs", "*.ts", "*.mts", "*.cts", "*.jsx", "*.tsx" },
  callback = function(args)
    -- Equal-priority markers select the nearest config, regardless of its name.
    local root = vim.fs.root(args.buf, { configs })
    if not root then return end
    vim.api.nvim_buf_call(args.buf, function()
      require("lint").try_lint("eslint_d", { cwd = root })
    end)
  end,
})
