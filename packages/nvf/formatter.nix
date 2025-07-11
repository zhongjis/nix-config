{pkgs, ...}: {
  extraPackages = with pkgs; [
    stylua
    nixpkgs-fmt
    alejandra
    shfmt
    prettierd
    black
    google-java-format
    xmlstarlet
  ];

  vim.languages.enableFormat = true;
  vim.formatter.conform-nvim = {
    enable = true;
    setupOpts = {
      formatters = {
        stylua = {
          prepend_args = [
            "--indent-type"
            "Spaces"
            "--indent-width"
            2
            "--column-width"
            85
            "--sort-requires"
          ];
        };
        black = {
          prepend_args = [
            "--line-length"
            85
          ];
        };
        shfmt = {
          args = [
            "-i"
            2
            "-ci"
          ];
        };
      };
      formatters_by_ft = {
        lua = ["stylua"];
        nix = ["alejandra"];
        sh = ["shfmt"];
        javascript = ["prettierd"];
        typescript = ["prettierd"];
        yaml = ["prettierd"];
        markdown = ["prettierd"];
        python = ["black"];
        css = ["prettierd"];
        terraform = ["terraform_fmt"];
        java = ["google-java-format"];
        xml = ["xmlstarlet"];
      };
      format_on_save = {
        _type = "lua-inline";
        expr = ''
          function(bufnr)
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
              end
        '';
      };
    };
  };
}
