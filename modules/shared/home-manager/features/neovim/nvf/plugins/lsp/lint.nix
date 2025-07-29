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
            local lint = require("lint")
            lint.linters_by_ft = {
              markdown = { "markdownlint" },
              terraform = { "tflint", "tfsec" },
            }

            local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
            vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
              group = lint_augroup,
              callback = function()
                if vim.opt_local.modifiable:get() then
                  lint.try_lint()
                end
              end
            })
          end
        '';
      };
    }
  ];
}
