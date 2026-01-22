{pkgs, ...}: {
  # nvim-lint configuration
  # Note: nvf handles the autocmd setup automatically when nvim-lint is enabled
  vim.diagnostics.nvim-lint = {
    enable = true;

    linters_by_ft = {
      markdown = ["markdownlint"];
      terraform = ["tflint" "tfsec"];
      python = ["ruff"]; # Fast Python linter
      javascript = ["eslint_d"];
      typescript = ["eslint_d"];
      javascriptreact = ["eslint_d"];
      typescriptreact = ["eslint_d"];
    };
  };

  vim.extraPackages = with pkgs; [
    tflint
    tfsec
    markdownlint-cli
    ruff # Fast Python linter
    eslint_d # Fast eslint daemon
  ];
}
