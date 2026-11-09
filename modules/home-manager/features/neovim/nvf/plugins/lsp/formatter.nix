{
  pkgs,
  lib,
  ...
}: {
  vim.extraPackages = with pkgs; [
    stylua
    nixpkgs-fmt
    alejandra
    shfmt
    prettierd
    black
    google-java-format
    xmlstarlet
    scalafmt
  ];

  vim.languages.enableFormat = true;
  vim.lsp.formatOnSave = true;
  vim.lsp.mappings.format = null;
  vim.formatter.conform-nvim = {
    enable = true;
    setupOpts = {
      formatters = {
        stylua = {
          prepend_args = [
            "--indent-type"
            "Spaces"
            "--indent-width"
            "2"
            "--column-width"
            "85"
            "--sort-requires"
          ];
        };
        shfmt = {
          args = [
            "-i"
            "2"
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
        typescriptreact = ["prettierd"];
        javascriptreact = ["prettierd"];
        yaml = ["prettierd"];
        markdown = ["prettierd"];
        python = ["black"];
        css = ["prettierd"];
        scss = ["prettierd"];
        terraform = ["terraform_fmt"];
        java = ["google-java-format"];
        scala = ["scalafmt"];
        sbt = ["scalafmt"];
        xml = ["xmlstarlet"];
        json = ["prettierd"];
        jsonc = ["prettierd"];
        html = ["prettierd"];
        graphql = ["prettierd"];
      };
      # Reads the flags set by :FormatEnable/:FormatDisable (lua/usrcmds.lua).
      format_on_save = lib.generators.mkLuaInline ''
        function(bufnr)
          if vim.g.formatsave == false or vim.b[bufnr].disableFormatSave then
            return
          end
          return {
            lsp_format = "fallback",
            -- google-java-format is a JVM; cold starts exceed 500ms
            timeout_ms = vim.bo[bufnr].filetype == "java" and 3000 or 500,
          }
        end
      '';
      format_after_save = null;
    };
  };
}
