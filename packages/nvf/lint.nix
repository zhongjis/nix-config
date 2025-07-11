{pkgs, ...}: {
  vim.diagnostics.nvim-lint = {
    enable = true;

    linters_by_ft = {
      markdown = ["markdownlint"];
      terraform = ["tflint" "tfsec"];
    };
  };

  vim.extraPackages = with pkgs; [
    tflint
    tfsec
    markdownlint-cli
  ];

  vim.augroups = [
    {
      enable = true;
      clear = true;
      name = "Lint";
    }
  ];

  vim.autocmds = [
    {
      enable = true;
      desc = "Auto lint doc.";
      event = ["BufEnter" "BufWritePost" "InsertLeave"];
      group = "Lint";
      callback = {
        _type = "lua-inline";
        expr = ''
          function()
            if vim.opt_local.modifiable:get() then
              lint.try_lint()
            end
          end
        '';
      };
    }
  ];
}
