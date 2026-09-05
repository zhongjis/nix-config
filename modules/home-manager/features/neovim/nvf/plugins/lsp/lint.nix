{pkgs, ...}: {
  # nvim-lint configuration
  # Note: nvf handles the autocmd setup automatically when nvim-lint is enabled
  vim.diagnostics.nvim-lint = {
    enable = true;

    linters_by_ft = {
      terraform = ["tflint" "tfsec"];
    };
  };

  vim.extraLuaFiles = [../../config/lua/eslint.lua];

  vim.extraPackages = with pkgs; [
    tflint
    tfsec
    eslint_d # Fast eslint daemon
  ];
}
